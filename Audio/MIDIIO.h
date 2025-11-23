//----------------------------------------------------------------------------------------------------------------------
// MIDI I/O library using RtMidi
// Copyright (c) 2024 Samuel Gomes
//
// https://learn.microsoft.com/en-us/windows/win32/multimedia/midi-reference
// http://web.archive.org/web/20051225001012/http://www.borg.com/~jglatt/
// https://www.personal.kent.edu/~sbirch/Music_Production/MP-II/MIDI/midi_file_format.htm
// http://www.somascape.org/midi/tech/spec.html
// https://www.dogsbodynet.com/fileformats/midi.html
// http://www.music.mcgill.ca/~gary/rtmidi/group__C-interface.html
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#ifndef RTMIDI_SOURCE_INCLUDED
    // Platform-specific API selection
    #ifdef _WIN32
        #define __WINDOWS_MM__
    #elif __APPLE__
        #define __MACOSX_CORE__
    #elif __linux__
        #define __LINUX_ALSA__
    #endif

    // This is needed since we are including the .cpp files
    #define RTMIDI_SOURCE_INCLUDED

    #include "../external/rtmidi/RtMidi.cpp"
    #include "../external/rtmidi/rtmidi_c.cpp"
#endif

#include "../Core/Types.h"
#include <cstdint>
#include <memory>
#include <mutex>
#include <queue>
#include <stack>
#include <string>
#include <unordered_map>

/// @brief A class to manage resource handles and associated resources.
/// @tparam Resource The type of the resource to manage.
template <typename Resource> class ResourceHandleManager {
  public:
    using Handle = int32_t;

    static const Handle InvalidHandle = 0;

    /// @brief Constructor - initializes handles, reserving 0 for invalid.
    ResourceHandleManager() : nextAvailableHandle(InvalidHandle + 1) {}

    /// @brief Creates a new handle and associates it with a resource.
    /// @param resource A unique pointer to the resource to store. Ownership is transferred.
    /// @return A unique handle identifying the stored resource.
    Handle CreateHandle(std::unique_ptr<Resource> resource) {
        Handle handle;
        if (!availableHandles.empty()) {
            handle = availableHandles.top();
            availableHandles.pop();
        } else {
            handle = nextAvailableHandle++;
        }

        handleToResourceMap[handle] = std::move(resource);

        return handle;
    }

    /// @brief Releases the resource associated with a handle.
    /// @param handle The handle of the resource to release.
    void ReleaseHandle(Handle handle) {
        auto it = handleToResourceMap.find(handle);
        if (it != handleToResourceMap.end()) {
            handleToResourceMap.erase(it);
            availableHandles.push(handle);
        }
    }

    /// @brief Retrieves a resource associated with a handle.
    /// @param handle The handle of the resource to retrieve.
    /// @return A pointer to the resource, or nullptr if the handle is invalid.
    Resource *GetResource(Handle handle) const {
        auto it = handleToResourceMap.find(handle);
        return (it != handleToResourceMap.end()) ? it->second.get() : nullptr;
    }

    /// @brief Checks if a handle is valid.
    /// @param handle The handle to check.
    /// @return True if the handle is valid, false otherwise.
    bool IsHandleValid(Handle handle) const {
        return handleToResourceMap.find(handle) != handleToResourceMap.end();
    }

  private:
    std::unordered_map<Handle, std::unique_ptr<Resource>> handleToResourceMap;
    std::stack<Handle> availableHandles;
    Handle nextAvailableHandle;
};

struct MIDIIOContext {
    static const auto InvalidPort = -1;
    static constexpr auto IOPortName = "QB64-PE";

    struct MIDIInputData {
        double timestamp;
        std::string message;

        MIDIInputData() : timestamp(0.0) {}

        MIDIInputData(double timestamp, std::string message) : timestamp(timestamp), message(std::move(message)) {}
    };

    bool isInput;
    RtMidiPtr rtMidi;
    int64_t port;
    std::queue<MIDIInputData> inputQueue;
    MIDIInputData input;
    mutable std::mutex inputQueueMutex;

    MIDIIOContext() : isInput(false), rtMidi(nullptr), port(InvalidPort) {}

    /// @brief Callback function to handle incoming MIDI messages.
    /// @param timeStamp The delta timestamp at which the message was received.
    /// @param message Pointer to the MIDI message data.
    /// @param messageSize The size of the MIDI message.
    /// @param userData Pointer to user-defined data, expected to be a MIDIIOContext instance.
    static void InputCallback(double timeStamp, const unsigned char *message, size_t messageSize, void *userData) {
        auto context = static_cast<MIDIIOContext *>(userData);
        if (context) {
            std::lock_guard<std::mutex> lock(context->inputQueueMutex);

            context->inputQueue.emplace(timeStamp, std::string(reinterpret_cast<const char *>(message), messageSize));
        }
    }
};

static ResourceHandleManager<MIDIIOContext> g_MIDIIOContextManager;

/// @brief Creates a MIDIIO context and returns a handle to it.
/// @param isInput Boolean indicating whether the context is for MIDI input.
/// @return A handle to the created MIDIIO context, or InvalidHandle if creation fails.
ResourceHandleManager<MIDIIOContext>::Handle MIDIIO_Create(qb_bool isInput) {
    auto handle = g_MIDIIOContextManager.CreateHandle(std::make_unique<MIDIIOContext>());
    auto context = g_MIDIIOContextManager.GetResource(handle);

    if (context) {
        context->rtMidi = isInput ? rtmidi_in_create_default() : rtmidi_out_create_default();

        if (context->rtMidi && context->rtMidi->ok) {
            context->isInput = bool(isInput);

            return handle;
        }
    }

    g_MIDIIOContextManager.ReleaseHandle(handle);

    return ResourceHandleManager<MIDIIOContext>::InvalidHandle;
}

/// @brief Deletes a MIDIIO context associated with a handle. It cancels any active MIDI input callbacks, closes the MIDI port if open.
/// frees the MIDI resources, and releases the handle.
/// @param handle The handle of the MIDIIO context to delete.
/// This function retrieves the MIDIIO context for the given handle,
void MIDIIO_Delete(ResourceHandleManager<MIDIIOContext>::Handle handle) {
    auto context = g_MIDIIOContextManager.GetResource(handle);
    if (context) {
        if (context->rtMidi) {
            if (context->port >= 0) {
                if (context->isInput) {
                    rtmidi_in_cancel_callback(context->rtMidi);
                }

                rtmidi_close_port(context->rtMidi);
            }

            if (context->isInput) {
                rtmidi_in_free(context->rtMidi);
            } else {
                rtmidi_out_free(context->rtMidi);
            }
        }
    }

    g_MIDIIOContextManager.ReleaseHandle(handle);
}

/// @brief Retrieves the last error message associated with a given MIDIIO context handle.
/// @param handle The handle of the MIDIIO context for which the error message is retrieved.
/// @return A pointer to the error message string if there is an error; otherwise, an empty string.
const char *MIDIIO_GetLastErrorMessage(ResourceHandleManager<MIDIIOContext>::Handle handle) {
    auto context = g_MIDIIOContextManager.GetResource(handle);

    return (context && context->rtMidi && !context->rtMidi->ok) ? context->rtMidi->msg : "";
}

/// @brief Retrieves the number of available MIDI ports for the given context.
/// @param handle The handle of the MIDIIO context for which the port count is retrieved.
/// @return The number of available MIDI ports if successful; otherwise, 0.
uint32_t MIDIIO_GetPortCount(ResourceHandleManager<MIDIIOContext>::Handle handle) {
    auto context = g_MIDIIOContextManager.GetResource(handle);
    if (context && context->rtMidi) {
        auto count = rtmidi_get_port_count(context->rtMidi);
        if (context->rtMidi->ok) {
            return count;
        }
    }

    return 0u;
}

/// @brief Retrieves the name of a MIDI port associated with a given context.
/// @param handle The handle of the MIDIIO context for which the port name is retrieved.
/// @param port The index of the MIDI port for which the name is retrieved.
/// @return The name of the MIDI port if successful; otherwise, an empty string.
const char *MIDIIO_GetPortName(ResourceHandleManager<MIDIIOContext>::Handle handle, uint32_t port) {
    static thread_local std::string buffer;

    auto context = g_MIDIIOContextManager.GetResource(handle);
    if (context && context->rtMidi) {
        auto bufLen = 0;
        rtmidi_get_port_name(context->rtMidi, port, nullptr, &bufLen); // get the required buffer size
        buffer.resize(bufLen);
        rtmidi_get_port_name(context->rtMidi, port, buffer.data(), &bufLen);

        if (context->rtMidi->ok) {
            return buffer.c_str();
        }
    }

    buffer.clear();

    return buffer.c_str();
}

/// @brief Retrieves the currently open MIDI port number associated with a given context.
/// @param handle The handle of the MIDIIO context for which the open port number is retrieved.
/// @return The currently open MIDI port number if successful; otherwise, InvalidPort.
int64_t MIDIIO_GetOpenPortNumber(ResourceHandleManager<MIDIIOContext>::Handle handle) {
    auto context = g_MIDIIOContextManager.GetResource(handle);

    return context ? context->port : MIDIIOContext::InvalidPort;
}

/// @brief Opens a MIDI port for the given context handle and port number. This function attempts to open the specified
/// MIDI port for the given context handle. If the port is already open, it returns true. If another port is open, it
/// returns false. For input ports, it also sets up a callback for incoming messages.
/// @param handle The handle of the MIDIIO context for which the port is to be opened.
/// @param port The index of the MIDI port to open.
/// @return QB_TRUE if the port is successfully opened or already open; otherwise, QB_FALSE.
qb_bool MIDIIO_OpenPort(ResourceHandleManager<MIDIIOContext>::Handle handle, uint32_t port) {
    auto context = g_MIDIIOContextManager.GetResource(handle);
    if (context && context->rtMidi) {
        if (int64_t(port) == context->port) {
            return QB_TRUE; // already open
        } else if (context->port >= 0) {
            return QB_FALSE; // some other port is already open
        }

        if (context->isInput) {
            rtmidi_open_port(context->rtMidi, port, MIDIIOContext::IOPortName);
            if (context->rtMidi->ok) {
                // Setup callback
                rtmidi_in_set_callback(context->rtMidi, MIDIIOContext::InputCallback, context);
                if (context->rtMidi->ok) {
                    context->port = port;

                    return QB_TRUE;
                }

                rtmidi_close_port(context->rtMidi);
            }
        } else {
            rtmidi_open_port(context->rtMidi, port, MIDIIOContext::IOPortName);
            if (context->rtMidi->ok) {
                context->port = port;

                return QB_TRUE;
            }
        }
    }

    return QB_FALSE;
}

/// @brief Closes a MIDI port for the given context handle. If no port is open or the handle is invalid, it does nothing.
/// @param handle The handle of the MIDIIO context for which the port is to be closed.
void MIDIIO_ClosePort(ResourceHandleManager<MIDIIOContext>::Handle handle) {
    auto context = g_MIDIIOContextManager.GetResource(handle);
    if (context && context->rtMidi && context->port >= 0) {
        if (context->isInput) {
            rtmidi_in_cancel_callback(context->rtMidi);
        }

        rtmidi_close_port(context->rtMidi);

        context->port = MIDIIOContext::InvalidPort;
    }
}

/// @brief Returns the number of available messages in the input queue and pops the first message.
/// @param port The port number.
/// @return The number of available messages.
size_t MIDIIO_GetMessageCount(ResourceHandleManager<MIDIIOContext>::Handle handle) {
    auto context = g_MIDIIOContextManager.GetResource(handle);
    if (context) {
        std::lock_guard<std::mutex> lock(context->inputQueueMutex);

        auto messages = context->inputQueue.size();
        if (messages) {
            context->input = context->inputQueue.front(); // get and store the first message
            context->inputQueue.pop();                    // remove the first message from the queue
        }

        return messages;
    }

    return 0;
}

/// @brief Returns the first message in the input queue.
/// @param port The port number.
/// @return The first message in the input queue.
const char *MIDIIO_GetMessage(ResourceHandleManager<MIDIIOContext>::Handle handle) {
    auto context = g_MIDIIOContextManager.GetResource(handle);

    return context ? context->input.message.c_str() : "";
}

/// @brief Returns the delta timestamp of the first message in the input queue.
/// @param port The port number.
/// @return The delta timestamp of the first message in the input queue.
double MIDIIO_GetTimestamp(ResourceHandleManager<MIDIIOContext>::Handle handle) {
    auto context = g_MIDIIOContextManager.GetResource(handle);

    return context ? context->input.timestamp : 0.0;
}

/// @brief Sets flags to ignore certain types of incoming MIDI messages for the given context.
/// @param handle The handle of the MIDIIO context for which the message types are to be ignored.
/// @param midiSysex Boolean indicating whether to ignore SYSEX messages.
/// @param midiTime Boolean indicating whether to ignore MIDI Time Code messages.
/// @param midiSense Boolean indicating whether to ignore MIDI Sense messages.
void MIDIIO_IgnoreMessageTypes(ResourceHandleManager<MIDIIOContext>::Handle handle, qb_bool midiSysex, qb_bool midiTime, qb_bool midiSense) {
    auto context = g_MIDIIOContextManager.GetResource(handle);
    if (context && context->rtMidi) {
        rtmidi_in_ignore_types(context->rtMidi, bool(midiSysex), bool(midiTime), bool(midiSense));
    }
}

/// @brief Sends a MIDI message through the specified context.
/// @param handle The handle of the MIDIIO context through which the message is to be sent.
/// @param message Pointer to the MIDI message data.
/// @param messageSize The size of the MIDI message.
inline void __MIDIIO_SendMessage(ResourceHandleManager<MIDIIOContext>::Handle handle, const char *message, size_t messageSize) {
    auto context = g_MIDIIOContextManager.GetResource(handle);
    if (context && context->rtMidi) {
        rtmidi_out_send_message(context->rtMidi, reinterpret_cast<const unsigned char *>(message), messageSize);
    }
}
