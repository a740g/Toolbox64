//----------------------------------------------------------------------------------------------------------------------
// MIDI I/O library using RtMidi
// Copyright (c) 2024 Samuel Gomes
//
// https://learn.microsoft.com/en-us/windows/win32/multimedia/midi-reference
// http://web.archive.org/web/20051225001012/http://www.borg.com/~jglatt/
// https://www.personal.kent.edu/~sbirch/Music_Production/MP-II/MIDI/midi_file_format.htm
// http://www.somascape.org/midi/tech/spec.html
// https://www.dogsbodynet.com/fileformats/midi.html
//----------------------------------------------------------------------------------------------------------------------

#pragma once

// TODO: Check if this is good enough.
#ifdef _WIN32
#define __WINDOWS_MM__
#elif __APPLE__
#define __MACOSX_CORE__
#elif __linux__
#define __LINUX_ALSA__
#endif

#define TOOLBOX64_DEBUG 0
#include "Debug.h"
#include "Common.h"
#include "Types.h"
#include "external/rtmidi/RtMidi.cpp"
#define RTMIDI_SOURCE_INCLUDED
#include "external/rtmidi/rtmidi_c.cpp"
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <vector>
#include <unordered_map>
#include <queue>
#include <stack>

/// @brief A class to manage resource handles and associated resources.
/// @tparam Resource The type of the resource to manage.
template <typename Resource>
class ResourceHandleManager
{
public:
    using Handle = int32_t;

    static const Handle InvalidHandle = 0;

    /// @brief Constructor - initializes handles, reserving 0 for invalid.
    ResourceHandleManager() : nextAvailableHandle(InvalidHandle + 1) {}

    /// @brief Creates a new handle and associates it with a resource.
    /// @param resource A unique pointer to the resource to store. Ownership is transferred.
    /// @return A unique handle identifying the stored resource.
    Handle CreateHandle(std::unique_ptr<Resource> resource)
    {
        Handle handle;
        if (!availableHandles.empty())
        {
            handle = availableHandles.top();
            availableHandles.pop();
        }
        else
        {
            handle = nextAvailableHandle++;
        }

        handleToResourceMap[handle] = std::move(resource);

        return handle;
    }

    /// @brief Releases the resource associated with a handle.
    /// @param handle The handle of the resource to release.
    void ReleaseHandle(Handle handle)
    {
        auto it = handleToResourceMap.find(handle);
        if (it != handleToResourceMap.end())
        {
            handleToResourceMap.erase(it);
            availableHandles.push(handle);
        }
    }

    /// @brief Retrieves a resource associated with a handle.
    /// @param handle The handle of the resource to retrieve.
    /// @return A pointer to the resource, or nullptr if the handle is invalid.
    Resource *GetResource(Handle handle) const
    {
        auto it = handleToResourceMap.find(handle);
        return (it != handleToResourceMap.end()) ? it->second.get() : nullptr;
    }

    /// @brief Checks if a handle is valid.
    /// @param handle The handle to check.
    /// @return True if the handle is valid, false otherwise.
    bool IsHandleValid(Handle handle) const
    {
        return handleToResourceMap.find(handle) != handleToResourceMap.end();
    }

private:
    std::unordered_map<Handle, std::unique_ptr<Resource>> handleToResourceMap;
    std::stack<Handle> availableHandles;
    Handle nextAvailableHandle;
};

struct MIDIIOContext
{
    static const auto InvalidPort = -1;
    static constexpr auto IOPortName = "QB64-PE";

    enum class Type
    {
        None,
        Input,
        Output
    };

    struct MIDIInputData
    {
        double timestamp;
        std::vector<uint8_t> message;

        MIDIInputData() : timestamp(0.0) {}

        MIDIInputData(double timestamp, std::vector<uint8_t> message) : timestamp(timestamp), message(std::move(message)) {}
    };

    Type type;
    RtMidiPtr rtMidi;
    int64_t port;
    std::queue<MIDIInputData> inputQueue;
    MIDIInputData input;

    MIDIIOContext() : type(Type::None), rtMidi(nullptr), port(InvalidPort) { input.timestamp = 0.0; }

    // Callback function to handle incoming MIDI messages
    static void InputCallback(double timeStamp, const unsigned char *message, size_t messageSize, void *userData)
    {
        // TODO: This needs to be thread-safe!!!
        auto context = static_cast<MIDIIOContext *>(userData);
        if (context)
        {
            context->inputQueue.emplace(timeStamp, std::vector<uint8_t>(message, message + messageSize));
        }
    }
};

static ResourceHandleManager<MIDIIOContext> g_MIDIIOContextManager;

ResourceHandleManager<MIDIIOContext>::Handle MIDIIO_Create(qb_bool isInput)
{
    auto ctxObj = std::make_unique<MIDIIOContext>();
    if (ctxObj)
    {
        TOOLBOX64_DEBUG_PRINT("Created MIDIIO context object");

        auto handle = g_MIDIIOContextManager.CreateHandle(std::move(ctxObj));

        if (g_MIDIIOContextManager.IsHandleValid(handle))
        {
            TOOLBOX64_DEBUG_PRINT("Handle: %d", handle);

            auto context = g_MIDIIOContextManager.GetResource(handle);
            if (context)
            {
                TOOLBOX64_DEBUG_PRINT("Got MIDIIO context");

                context->rtMidi = isInput ? rtmidi_in_create_default() : rtmidi_out_create_default();

                if (context->rtMidi)
                {
                    TOOLBOX64_DEBUG_PRINT("Created RtMidi object");

                    if (context->rtMidi->ok)
                    {
                        TOOLBOX64_DEBUG_PRINT("RtMidi object created without error");

                        context->type = isInput ? MIDIIOContext::Type::Input : MIDIIOContext::Type::Output;

                        return handle;
                    }
                    else
                    {
                        TOOLBOX64_DEBUG_PRINT("RtMidi object created with error: %s", context->rtMidi->msg);

                        g_MIDIIOContextManager.ReleaseHandle(handle);
                    }
                }
                else
                {
                    TOOLBOX64_DEBUG_PRINT("Failed to create RtMidi object");

                    g_MIDIIOContextManager.ReleaseHandle(handle);
                }
            }
            else
            {
                TOOLBOX64_DEBUG_PRINT("Failed to get MIDIIO context");

                g_MIDIIOContextManager.ReleaseHandle(handle);
            }
        }
    }

    TOOLBOX64_DEBUG_PRINT("Failed to create MIDIIO context");

    return ResourceHandleManager<MIDIIOContext>::InvalidHandle;
}

void MIDIIO_Delete(ResourceHandleManager<MIDIIOContext>::Handle handle)
{
    if (g_MIDIIOContextManager.IsHandleValid(handle))
    {
        auto context = g_MIDIIOContextManager.GetResource(handle);
        if (context)
        {
            TOOLBOX64_DEBUG_PRINT("Got MIDIIO context");

            if (context->rtMidi)
            {
                TOOLBOX64_DEBUG_PRINT("RtMidi object exists");

                if (context->type == MIDIIOContext::Type::Input || context->type == MIDIIOContext::Type::Output)
                {
                    if (context->port >= 0)
                    {
                        TOOLBOX64_DEBUG_PRINT("Closing port: %lld", context->port);

                        rtmidi_close_port(context->rtMidi);
                    }

                    rtmidi_in_free(context->rtMidi);

                    TOOLBOX64_DEBUG_PRINT("RtMidi object freed");
                }
            }

            TOOLBOX64_DEBUG_PRINT("Releasing handle: %d", handle);
        }

        g_MIDIIOContextManager.ReleaseHandle(handle);
    }
}

uint32_t MIDIIO_GetPortCount(ResourceHandleManager<MIDIIOContext>::Handle handle)
{
    if (g_MIDIIOContextManager.IsHandleValid(handle))
    {
        auto context = g_MIDIIOContextManager.GetResource(handle);
        if (context)
        {
            if (context->rtMidi)
            {
                auto count = rtmidi_get_port_count(context->rtMidi);
                if (context->rtMidi->ok)
                {
                    return count;
                }
                else
                {
                    TOOLBOX64_DEBUG_PRINT("RtMidi error: %s", context->rtMidi->msg);
                }
            }
        }
    }

    return 0;
}

const char *MIDIIO_GetPortName(ResourceHandleManager<MIDIIOContext>::Handle handle, uint32_t port)
{
    g_TmpBuf[0] = '\0';

    if (g_MIDIIOContextManager.IsHandleValid(handle))
    {
        auto context = g_MIDIIOContextManager.GetResource(handle);
        if (context)
        {
            if (context->rtMidi)
            {
                int tmpBufLen = sizeof(g_TmpBuf);
                rtmidi_get_port_name(context->rtMidi, port, reinterpret_cast<char *>(g_TmpBuf), &tmpBufLen);
                g_TmpBuf[tmpBufLen - 1] = '\0';

                if (context->rtMidi->ok)
                {
                    return reinterpret_cast<char *>(g_TmpBuf);
                }
                else
                {
                    g_TmpBuf[0] = '\0';

                    TOOLBOX64_DEBUG_PRINT("RtMidi error: %s", context->rtMidi->msg);
                }
            }
        }
    }

    return reinterpret_cast<char *>(g_TmpBuf);
}

int64_t MIDIIO_GetOpenPortNumber(ResourceHandleManager<MIDIIOContext>::Handle handle)
{
    if (g_MIDIIOContextManager.IsHandleValid(handle))
    {
        auto context = g_MIDIIOContextManager.GetResource(handle);
        if (context)
        {
            return context->port;
        }
    }

    return MIDIIOContext::InvalidPort;
}

qb_bool MIDIIO_OpenPort(ResourceHandleManager<MIDIIOContext>::Handle handle, uint32_t port)
{
    if (g_MIDIIOContextManager.IsHandleValid(handle))
    {
        auto context = g_MIDIIOContextManager.GetResource(handle);
        if (context)
        {
            if (int64_t(port) == context->port)
            {
                return QB_TRUE; // already open
            }
            else if (context->port >= 0)
            {
                return QB_FALSE; // some other port is already open
            }

            if (context->rtMidi)
            {
                if (context->type == MIDIIOContext::Type::Input)
                {
                    rtmidi_open_port(context->rtMidi, port, MIDIIOContext::IOPortName);
                    if (context->rtMidi->ok)
                    {
                        // Setup callback
                        rtmidi_in_set_callback(context->rtMidi, MIDIIOContext::InputCallback, context);
                        if (context->rtMidi->ok)
                        {
                            context->port = port;

                            return QB_TRUE;
                        }

                        TOOLBOX64_DEBUG_PRINT("RtMidi error: %s", context->rtMidi->msg);

                        rtmidi_close_port(context->rtMidi);
                    }
                    else
                    {
                        TOOLBOX64_DEBUG_PRINT("RtMidi error: %s", context->rtMidi->msg);
                    }
                }
                else if (context->type == MIDIIOContext::Type::Output)
                {
                    rtmidi_open_port(context->rtMidi, port, MIDIIOContext::IOPortName);
                    if (context->rtMidi->ok)
                    {
                        context->port = port;
                        return QB_TRUE;
                    }
                    else
                    {
                        TOOLBOX64_DEBUG_PRINT("RtMidi error: %s", context->rtMidi->msg);
                    }
                }
            }
        }
    }

    return QB_FALSE;
}

void MIDIIO_ClosePort(ResourceHandleManager<MIDIIOContext>::Handle handle)
{
    if (g_MIDIIOContextManager.IsHandleValid(handle))
    {
        auto context = g_MIDIIOContextManager.GetResource(handle);
        if (context)
        {
            if (context->port >= 0)
            {
                if (context->rtMidi)
                {
                    if (context->type == MIDIIOContext::Type::Input)
                    {
                        TOOLBOX64_DEBUG_PRINT("Cancelling callback for port: %lld", context->port);

                        rtmidi_in_cancel_callback(context->rtMidi);
                    }

                    TOOLBOX64_DEBUG_PRINT("Closing port: %lld", context->port);

                    rtmidi_close_port(context->rtMidi);

                    context->port = MIDIIOContext::InvalidPort;
                }
            }
        }
    }
}

/// @brief Returns the number of available messages in the input queue and pops the first message.
/// @param port The port number.
/// @return The number of available messages.
size_t MIDIIO_GetMessageCount(ResourceHandleManager<MIDIIOContext>::Handle handle)
{
    // TODO: This needs to be thread-safe!!!

    if (g_MIDIIOContextManager.IsHandleValid(handle))
    {
        auto context = g_MIDIIOContextManager.GetResource(handle);
        if (context)
        {
            auto inputs = context->inputQueue.size();
            if (inputs)
            {
                context->input = context->inputQueue.front(); // get and store the first message
                context->inputQueue.pop();                    // remove the first message from the queue
            }

            return inputs;
        }
    }

    return 0;
}

/// @brief Returns the first message in the input queue.
/// @param port The port number.
/// @return The first message in the input queue.
const char *MIDIIO_GetMessage(ResourceHandleManager<MIDIIOContext>::Handle handle)
{
    g_TmpBuf[0] = '\0';

    if (g_MIDIIOContextManager.IsHandleValid(handle))
    {
        auto context = g_MIDIIOContextManager.GetResource(handle);
        if (context)
        {
            // Copy the message data to a temporary buffer and null terminate
            memcpy(g_TmpBuf, context->input.message.data(), std::min(context->input.message.size(), sizeof(g_TmpBuf)));
            g_TmpBuf[std::min(context->input.message.size(), sizeof(g_TmpBuf) - 1)] = '\0';

            return reinterpret_cast<char *>(g_TmpBuf);
        }
    }

    return reinterpret_cast<char *>(g_TmpBuf);
}

/// @brief Returns the timestamp of the first message in the input queue.
/// @param port The port number.
/// @return The timestamp of the first message in the input queue.
double MIDIIO_GetTimestamp(ResourceHandleManager<MIDIIOContext>::Handle handle)
{
    if (g_MIDIIOContextManager.IsHandleValid(handle))
    {
        auto context = g_MIDIIOContextManager.GetResource(handle);
        if (context)
        {
            return context->input.timestamp;
        }
    }

    return 0.0;
}

void MIDIIO_IgnoreMessageTypes(ResourceHandleManager<MIDIIOContext>::Handle handle, qb_bool midiSysex, qb_bool midiTime, qb_bool midiSense)
{
    if (g_MIDIIOContextManager.IsHandleValid(handle))
    {
        auto context = g_MIDIIOContextManager.GetResource(handle);
        if (context)
        {
            if (context->type == MIDIIOContext::Type::Input && context->rtMidi)
            {
                rtmidi_in_ignore_types(context->rtMidi, bool(midiSysex), bool(midiTime), bool(midiSense));
            }
        }
    }
}

void MIDIIO_SendMessage(ResourceHandleManager<MIDIIOContext>::Handle handle, const char *message, size_t messageSize)
{
    if (g_MIDIIOContextManager.IsHandleValid(handle))
    {
        auto context = g_MIDIIOContextManager.GetResource(handle);
        if (context)
        {
            if (context->type == MIDIIOContext::Type::Output && context->port >= 0 && context->rtMidi)
            {
                rtmidi_out_send_message(context->rtMidi, reinterpret_cast<const unsigned char *>(message), messageSize);
            }
        }
    }
}
