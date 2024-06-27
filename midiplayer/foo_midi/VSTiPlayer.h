#pragma once

#include "MIDIPlayer.h"
#include "InstrumentBankManager.h"

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

    uint32_t GetActiveVoiceCount() const override
    {
        // FIXME: Check if we can get the info from the VSTi
        return 128;
    };

    bool LoadVST(const char *path);

    void GetVendorName(std::string &out) const;
    void GetProductName(std::string &out) const;
    uint32_t GetVendorVersion() const noexcept;
    uint32_t GetUniqueID() const noexcept;

    // Configuration
    void GetChunk(std::vector<uint8_t> &data);
    void SetChunk(const void *data, size_t size);

    // Editor
    bool HasEditor();
    void DisplayEditorModal();

    typedef void *HANDLE;

protected:
    virtual bool Startup() override;
    virtual void Shutdown() override;
    virtual void Render(audio_sample *buffer, uint32_t frames) override;

    virtual uint32_t GetSampleBlockSize() const noexcept override { return renderFrames; }

    virtual void SendEvent(uint32_t data) override;
    virtual void SendSysEx(const uint8_t *data, size_t size, uint32_t portNumber) override;

    virtual void SendEvent(uint32_t data, uint32_t time) override;
    virtual void SendSysEx(const uint8_t *, size_t, uint32_t portNumber, uint32_t time) override;

private:
    bool StartHost();
    void StopHost() noexcept;
    bool IsHostRunning() noexcept;

    uint32_t ReadCode() noexcept;

    void ReadBytes(void *data, uint32_t size) noexcept;
    uint32_t ReadBytesOverlapped(void *data, uint32_t size) noexcept;

    void WriteBytes(uint32_t code) noexcept;
    void WriteBytesOverlapped(const void *data, uint32_t size) noexcept;

private:
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
};
