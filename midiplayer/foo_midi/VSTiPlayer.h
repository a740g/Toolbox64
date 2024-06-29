#pragma once

#include "MIDIPlayer.h"
#include "InstrumentBankManager.h"
#include <windows.h>
#include <combaseapi.h>
#include <sstream>

// Replace this with "filepath.h" once integration is complete
extern void filepath_split(const std::string &filePath, std::string &directory, std::string &fileName);
extern void filepath_join(std::string &filePath, const std::string &directory, const std::string &fileName);

class VSTiPlayer : public MIDIPlayer
{
public:
    VSTiPlayer() = delete;
    VSTiPlayer(const VSTiPlayer &) = delete;
    VSTiPlayer(VSTiPlayer &&) = delete;
    VSTiPlayer &operator=(const VSTiPlayer &) = delete;
    VSTiPlayer &operator=(VSTiPlayer &&) = delete;

    VSTiPlayer(InstrumentBankManager *ibm);
    virtual ~VSTiPlayer();

    virtual uint32_t GetActiveVoiceCount() const override { return 128; };

    virtual uint32_t GetSampleBlockSize() const noexcept override { return renderFrames; }

    // Configuration
    void GetChunk(std::vector<uint8_t> &data);
    void SetChunk(const void *data, size_t size);

    // Editor
    bool HasEditor();
    void DisplayEditorModal();

protected:
    virtual bool Startup() override;
    virtual void Shutdown() override;
    virtual void Render(audio_sample *buffer, uint32_t frames) override;

    virtual void SendEvent(uint32_t data) override;
    virtual void SendSysEx(const uint8_t *data, size_t size, uint32_t portNumber) override;

    virtual void SendEvent(uint32_t data, uint32_t time) override;
    virtual void SendSysEx(const uint8_t *, size_t, uint32_t portNumber, uint32_t time) override;

private:
    enum class VSTHostCommand : uint32_t
    {
        Exit = 0,
        GetChunk,
        SetChunk,
        HasEditor,
        DisplayEditorModal,
        SetSampleRate,
        Reset,
        SendMIDIEvent,
        SendSysexEvent,
        RenderSamples,
        SendMIDIEventWithTimestamp,
        SendSysexEventWithTimestamp,
    };

    static const uint32_t renderFrames = 4096u;

    InstrumentBankManager *instrumentBankManager;

    uint32_t _ProcessorArchitecture;
    bool _IsCOMInitialized;

    std::string _FilePath;

    HANDLE _hReadEvent;
    HANDLE _hPipeInRead;
    HANDLE _hPipeInWrite;
    HANDLE _hPipeOutRead;
    HANDLE _hPipeOutWrite;
    HANDLE _hProcess;
    HANDLE _hThread;

    std::string _Name;
    std::string _VendorName;
    std::string _ProductName;

    uint32_t _VendorVersion;
    uint32_t _UniqueId;

    uint32_t _ChannelCount;

    std::vector<uint8_t> _Chunk;
    std::vector<float> _Samples;

    bool _IsTerminating;

    bool StartHost();
    void StopHost() noexcept;
    bool IsHostRunning() noexcept;

    uint32_t ReadCode() noexcept;

    void ReadBytes(void *data, uint32_t size) noexcept;
    uint32_t ReadBytesOverlapped(void *data, uint32_t size) noexcept;

    void WriteBytes(uint32_t code) noexcept;
    void WriteBytesOverlapped(const void *data, uint32_t size) noexcept;
};
