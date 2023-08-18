//----------------------------------------------------------------------------------------------------------------------
// MIDI Player library using Win32 WinMM MIDI streaming API
// Copyright (c) 2023 Samuel Gomes
//
// This is a heavily modiified version of the Win32 native MIDI codec from SDL_mixer
// https://github.com/libsdl-org/SDL_mixer/tree/main/src/codecs/native_midi
//
// native_midi: Hardware Midi support for the SDL_mixer library
// Copyright(C) 2000, 2001  Florian 'Proff' Schulze <florian.proff.schulze@gmx.net>
// This software is provided 'as-is', without any express or implied
// warranty.In no event will the authors be held liable for any damages
// arising from the use of this software.
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter itand redistribute it
// freely, subject to the following restrictions :
// 1. The origin of this software must not be misrepresented; you must not
// claim that you wrote the original software.If you use this software
// in a product, an acknowledgment in the product documentation would be
// appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
// misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "Common.h"
#include "Types.h"
#include "MathOps.h"
#include "MemFile.h"
#include <cstdint>
#include <windows.h>

/* MIDI Status Bytes */
#define MIDI_STATUS_NOTE_OFF 0x8
#define MIDI_STATUS_NOTE_ON 0x9
#define MIDI_STATUS_AFTERTOUCH 0xA
#define MIDI_STATUS_CONTROLLER 0xB
#define MIDI_STATUS_PROG_CHANGE 0xC
#define MIDI_STATUS_PRESSURE 0xD
#define MIDI_STATUS_PITCH_WHEEL 0xE
#define MIDI_STATUS_SYSEX 0xF
/* The constant 'MThd' */
#define MIDI_MAGIC 0x4d546864

/* We store the midi events in a linked list; this way it is
   easy to shuffle the tracks together later on; and we are
   flexible in the size of each elemnt.
 */
struct MIDIEvent
{
    uint32_t time;     /* Time at which this midi events occurs */
    uint8_t status;    /* Status byte */
    uint8_t data[2];   /* 1 or 2 bytes additional data for most events */
    uint32_t extraLen; /* For some SysEx events, we need additional storage */
    uint8_t *extraData;
    MIDIEvent *next;
};

/* A single midi track as read from the midi file */
struct MIDITrack
{
    uint8_t *data; /* MIDI message stream */
    int len;       /* length of the track data */
};

/* A midi file, stripped down to the absolute minimum - divison & track data */
struct MIDIFile
{
    int division;     /* number of pulses per quarter note (ppqn) */
    int nTracks;      /* number of tracks */
    MIDITrack *track; /* tracks */
};

struct MIDISong
{
    bool MusicLoaded;
    bool MusicPlaying;
    bool MusicPaused;
    int Loops;
    int CurrentHdr;
    MIDIHDR MIDIStreamHdr[2];
    MIDIEVENT *NewEvents;
    uint16_t ppqn;
    int Size;
    int NewPos;
};

static UINT MIDIDevice = MIDI_MAPPER;
static HMIDISTRM hMIDIStream = nullptr;
static MIDISong *pMIDISong = nullptr;

/* Get Variable Length Quantity */
static int MIDIGetVLQ(MIDITrack *track, int *currentPos)
{
    int l = 0;
    uint8_t c;
    for (;;)
    {
        c = track->data[*currentPos];
        (*currentPos)++;
        l += (c & 0x7f);
        if (!(c & 0x80))
            return l;
        l <<= 7;
    }
}

/* Create a single MIDIEvent */
static MIDIEvent *MIDICreateEvent(uint32_t time, uint8_t evnt, uint8_t a, uint8_t b)
{
    auto newEvent = (MIDIEvent *)calloc(1, sizeof(MIDIEvent));

    if (newEvent)
    {
        newEvent->time = time;
        newEvent->status = evnt;
        newEvent->data[0] = a;
        newEvent->data[1] = b;
    }

    return newEvent;
}

/* Release a MIDIEvent list after usage. */
static void MIDIFreeEventList(MIDIEvent *head)
{
    MIDIEvent *cur, *next;

    cur = head;

    while (cur)
    {
        next = cur->next;
        if (cur->extraData)
            free(cur->extraData);
        free(cur);
        cur = next;
    }
}

/* Convert a single midi track to a list of MIDIEvents */
static MIDIEvent *MIDITrackToStream(MIDITrack *track)
{
    uint32_t atime = 0;
    uint32_t len = 0;
    uint8_t evnt, type, a, b;
    uint8_t laststatus = 0;
    uint8_t lastchan = 0;
    int currentPos = 0;
    int end = 0;
    MIDIEvent *head = MIDICreateEvent(0, 0, 0, 0); /* dummy event to make handling the list easier */
    MIDIEvent *currentEvent = head;

    while (!end)
    {
        if (currentPos >= track->len)
            break; /* End of data stream reached */

        atime += MIDIGetVLQ(track, &currentPos);
        evnt = track->data[currentPos++];

        /* Handle SysEx seperatly */
        if (((evnt >> 4) & 0x0F) == MIDI_STATUS_SYSEX)
        {
            if (evnt == 0xFF)
            {
                type = track->data[currentPos];
                currentPos++;
                switch (type)
                {
                case 0x2f: /* End of data marker */
                    end = 1;
                    [[fallthrough]];
                case 0x51: /* Tempo change */
                    /*
                    a=track->data[currentPos];
                    b=track->data[currentPos+1];
                    c=track->data[currentPos+2];
                    AddEvent(song, atime, MEVT_TEMPO, c, b, a);
                    */
                    break;
                }
            }
            else
                type = 0;

            len = MIDIGetVLQ(track, &currentPos);

            /* Create an event and attach the extra data, if any */
            currentEvent->next = MIDICreateEvent(atime, evnt, type, 0);
            currentEvent = currentEvent->next;
            if (nullptr == currentEvent)
            {
                MIDIFreeEventList(head);
                return nullptr;
            }
            if (len)
            {
                currentEvent->extraLen = len;
                currentEvent->extraData = (uint8_t *)malloc(len);
                if (currentEvent->extraData)
                    memcpy(currentEvent->extraData, &(track->data[currentPos]), len);
                currentPos += len;
            }
        }
        else
        {
            a = evnt;
            if (a & 0x80) /* It's a status byte */
            {
                /* Extract channel and status information */
                lastchan = a & 0x0F;
                laststatus = (a >> 4) & 0x0F;

                /* Read the next byte which should always be a data byte */
                a = track->data[currentPos++] & 0x7F;
            }
            switch (laststatus)
            {
            case MIDI_STATUS_NOTE_OFF:
            case MIDI_STATUS_NOTE_ON:     /* Note on */
            case MIDI_STATUS_AFTERTOUCH:  /* Key Pressure */
            case MIDI_STATUS_CONTROLLER:  /* Control change */
            case MIDI_STATUS_PITCH_WHEEL: /* Pitch wheel */
                b = track->data[currentPos++] & 0x7F;
                currentEvent->next = MIDICreateEvent(atime, (uint8_t)((laststatus << 4) + lastchan), a, b);
                currentEvent = currentEvent->next;
                if (nullptr == currentEvent)
                {
                    MIDIFreeEventList(head);
                    return nullptr;
                }
                break;

            case MIDI_STATUS_PROG_CHANGE: /* Program change */
            case MIDI_STATUS_PRESSURE:    /* Channel pressure */
                a &= 0x7f;
                currentEvent->next = MIDICreateEvent(atime, (uint8_t)((laststatus << 4) + lastchan), a, 0);
                currentEvent = currentEvent->next;
                if (nullptr == currentEvent)
                {
                    MIDIFreeEventList(head);
                    return nullptr;
                }
                break;

            default: /* Sysex already handled above */
                break;
            }
        }
    }

    currentEvent = head->next;
    free(head); /* release the dummy head event */
    return currentEvent;
}

/*
 *  Convert a midi song, consisting of up to 32 tracks, to a list of MIDIEvents.
 *  To do so, first convert the tracks seperatly, then interweave the resulting
 *  MIDIEvent-Lists to one big list.
 */
static MIDIEvent *MIDIToStream(MIDIFile *mididata)
{
    MIDIEvent **track;
    MIDIEvent *head = MIDICreateEvent(0, 0, 0, 0); /* dummy event to make handling the list easier */
    MIDIEvent *currentEvent = head;
    int trackID;

    if (nullptr == head)
        return nullptr;

    track = (MIDIEvent **)calloc(1, sizeof(MIDIEvent *) * mididata->nTracks);
    if (nullptr == track)
    {
        free(head);
        return nullptr;
    }

    /* First, convert all tracks to MIDIEvent lists */
    for (trackID = 0; trackID < mididata->nTracks; trackID++)
        track[trackID] = MIDITrackToStream(&mididata->track[trackID]);

    /* Now, merge the lists. */
    /* TODO */
    for (;;)
    {
        uint32_t lowestTime = INT_MAX;
        int currentTrackID = -1;

        /* Find the next event */
        for (trackID = 0; trackID < mididata->nTracks; trackID++)
        {
            if (track[trackID] && (track[trackID]->time < lowestTime))
            {
                currentTrackID = trackID;
                lowestTime = track[currentTrackID]->time;
            }
        }

        /* Check if we processes all events */
        if (currentTrackID == -1)
            break;

        currentEvent->next = track[currentTrackID];
        track[currentTrackID] = track[currentTrackID]->next;

        currentEvent = currentEvent->next;

        lowestTime = 0;
    }

    /* Make sure the list is properly terminated */
    currentEvent->next = 0;

    currentEvent = head->next;
    free(track);
    free(head); /* release the dummy head event */
    return currentEvent;
}

static bool MIDIReadFile(MIDIFile *mididata, uintptr_t src)
{
    int i = 0;
    uint32_t ID;
    uint32_t size;
    uint16_t format;
    uint16_t tracks;
    uint16_t division;

    if (!mididata)
        return false;
    if (!src)
        return false;

    /* Make sure this is really a MIDI file */
    MemFile_ReadLong(src, &ID);
    if (__builtin_bswap32(ID) != MIDI_MAGIC)
        return false;

    /* Header size must be 6 */
    MemFile_ReadLong(src, &size);
    size = __builtin_bswap32(size);
    if (size != 6)
        return false;

    /* We only support format 0 and 1, but not 2 */
    MemFile_ReadInteger(src, &format);
    format = __builtin_bswap16(format);
    if (format != 0 && format != 1)
        return false;

    MemFile_ReadInteger(src, &tracks);
    tracks = __builtin_bswap16(tracks);
    mididata->nTracks = tracks;

    /* Allocate tracks */
    mididata->track = (MIDITrack *)calloc(1, sizeof(MIDITrack) * mididata->nTracks);
    if (nullptr == mididata->track)
    {
        goto bail;
    }

    /* Retrieve the PPQN value, needed for playback */
    MemFile_ReadInteger(src, &division);
    mididata->division = __builtin_bswap16(division);

    for (i = 0; i < tracks; i++)
    {
        MemFile_ReadLong(src, &ID); /* We might want to verify this is MTrk... */
        TOOLBOX64_DEBUG_CHECK(__builtin_bswap32(ID) == 0x4d54726b);
        MemFile_ReadLong(src, &size);
        size = __builtin_bswap32(size);
        mididata->track[i].len = size;
        mididata->track[i].data = (uint8_t *)malloc(size);
        if (nullptr == mididata->track[i].data)
        {
            goto bail;
        }
        MemFile_Read(src, reinterpret_cast<uintptr_t>(mididata->track[i].data), size);
    }

    return true;

bail:
    for (; i >= 0; i--)
    {
        if (mididata->track[i].data)
            free(mididata->track[i].data);
    }

    return false;
}

/* Load a midifile to memory, converting it to a list of MIDIEvents.
   This function returns a linked lists of MIDIEvents, 0 if an error occured.
 */
static MIDIEvent *MIDICreateEventList(uintptr_t src, uint16_t *division)
{
    MIDIFile *mididata = nullptr;
    MIDIEvent *eventList;
    int trackID;

    mididata = (MIDIFile *)calloc(1, sizeof(MIDIFile));
    if (!mididata)
        return nullptr;

    /* Open the file */
    if (src)
    {
        /* Read in the data */
        if (!MIDIReadFile(mididata, src))
        {
            free(mididata);
            return nullptr;
        }
    }
    else
    {
        free(mididata);
        return nullptr;
    }

    if (division)
        *division = (uint16_t)mididata->division;

    eventList = MIDIToStream(mididata);
    if (nullptr == eventList)
    {
        free(mididata);
        return nullptr;
    }
    for (trackID = 0; trackID < mididata->nTracks; trackID++)
    {
        if (mididata->track[trackID].data)
            free(mididata->track[trackID].data);
    }
    free(mididata->track);
    free(mididata);

    return eventList;
}

static bool MIDIBlockOut()
{
    if ((pMIDISong->MusicLoaded) && (pMIDISong->NewEvents))
    {
        // proff 12/8/98: Added for safety
        pMIDISong->CurrentHdr = !pMIDISong->CurrentHdr;
        MIDIHDR *hdr = &pMIDISong->MIDIStreamHdr[pMIDISong->CurrentHdr];
        midiOutUnprepareHeader((HMIDIOUT)hMIDIStream, hdr, sizeof(MIDIHDR));
        if (pMIDISong->NewPos >= pMIDISong->Size)
            return false;
        int BlockSize = (pMIDISong->Size - pMIDISong->NewPos);
        if (BlockSize <= 0)
            return false;
        if (BlockSize > 36000)
            BlockSize = 36000;
        hdr->lpData = (LPSTR)((unsigned char *)pMIDISong->NewEvents + pMIDISong->NewPos);
        pMIDISong->NewPos += BlockSize;
        hdr->dwBufferLength = BlockSize;
        hdr->dwBytesRecorded = BlockSize;
        hdr->dwFlags = 0;
        hdr->dwOffset = 0;
        MMRESULT err = midiOutPrepareHeader((HMIDIOUT)hMIDIStream, hdr, sizeof(MIDIHDR));
        if (err != MMSYSERR_NOERROR)
            return false;
        err = midiStreamOut(hMIDIStream, hdr, sizeof(MIDIHDR));
        return false;
    }
    return true;
}

static void MIDIToStream(MIDIEvent *evntlist)
{
    int eventcount;
    MIDIEvent *evnt;
    MIDIEVENT *newevent;

    eventcount = 0;
    evnt = evntlist;
    while (evnt)
    {
        eventcount++;
        evnt = evnt->next;
    }
    pMIDISong->NewEvents = (MIDIEVENT *)malloc(eventcount * 3 * sizeof(DWORD));
    if (!pMIDISong->NewEvents)
        return;
    memset(pMIDISong->NewEvents, 0, (eventcount * 3 * sizeof(DWORD)));

    eventcount = 0;
    evnt = evntlist;
    newevent = pMIDISong->NewEvents;
    while (evnt)
    {
        int status = (evnt->status & 0xF0) >> 4;
        switch (status)
        {
        case MIDI_STATUS_NOTE_OFF:
        case MIDI_STATUS_NOTE_ON:
        case MIDI_STATUS_AFTERTOUCH:
        case MIDI_STATUS_CONTROLLER:
        case MIDI_STATUS_PROG_CHANGE:
        case MIDI_STATUS_PRESSURE:
        case MIDI_STATUS_PITCH_WHEEL:
            newevent->dwDeltaTime = evnt->time;
            newevent->dwEvent = (evnt->status | 0x80) | (evnt->data[0] << 8) | (evnt->data[1] << 16) | (MEVT_SHORTMSG << 24);
            newevent = (MIDIEVENT *)((char *)newevent + (3 * sizeof(DWORD)));
            eventcount++;
            break;

        case MIDI_STATUS_SYSEX:
            if (evnt->status == 0xFF && evnt->data[0] == 0x51) /* Tempo change */
            {
                int tempo = evnt->extraData ? ((evnt->extraData[0] << 16) | (evnt->extraData[1] << 8) | evnt->extraData[2]) : 120;
                newevent->dwDeltaTime = evnt->time;
                newevent->dwEvent = (MEVT_TEMPO << 24) | tempo;
                newevent = (MIDIEVENT *)((char *)newevent + (3 * sizeof(DWORD)));
                eventcount++;
            }
            break;
        }

        evnt = evnt->next;
    }

    pMIDISong->Size = eventcount * 3 * sizeof(DWORD);

    {
        int time;
        int temptime;

        pMIDISong->NewPos = 0;
        time = 0;
        newevent = pMIDISong->NewEvents;
        while (pMIDISong->NewPos < pMIDISong->Size)
        {
            temptime = newevent->dwDeltaTime;
            newevent->dwDeltaTime -= time;
            time = temptime;
            if ((pMIDISong->NewPos + 12) >= pMIDISong->Size)
                newevent->dwEvent |= MEVT_F_CALLBACK;
            newevent = (MIDIEVENT *)((char *)newevent + (3 * sizeof(DWORD)));
            pMIDISong->NewPos += 12;
        }
    }
    pMIDISong->NewPos = 0;
    pMIDISong->MusicLoaded = true;
}

static void CALLBACK MIDIProc(HMIDIIN hMIDI, UINT uMsg, DWORD_PTR dwInstance, DWORD_PTR dwParam1, DWORD_PTR dwParam2)
{
    (void)hMIDI;
    (void)dwInstance;
    (void)dwParam2;

    switch (uMsg)
    {
    case MOM_DONE:
        if ((pMIDISong->MusicLoaded) && (dwParam1 == (DWORD_PTR)&pMIDISong->MIDIStreamHdr[pMIDISong->CurrentHdr]))
            MIDIBlockOut();
        break;

    case MOM_POSITIONCB:
        if ((pMIDISong->MusicLoaded) && (dwParam1 == (DWORD_PTR)&pMIDISong->MIDIStreamHdr[pMIDISong->CurrentHdr]))
        {
            if (pMIDISong->Loops)
            {
                if (pMIDISong->Loops > 0)
                    --pMIDISong->Loops;
                pMIDISong->NewPos = 0;
                MIDIBlockOut();
            }
            else
            {
                pMIDISong->MusicPlaying = false;
            }
        }
        break;

    default:
        break;
    }
}

/// @brief This loads and starts playing a MIDI file from memory.
/// Specifying a new file while another one is playing will stop the previous file and then start playing the new one.
/// If buffer is NULL, then it will shutdown MIDI playback and free allocated resources
/// @param buffer A buffer containing a Standard MIDI file
/// @param bufferSize The size of the buffer
/// @return QB_TRUE if the call succeeded. QB_FALSE otherwise
inline qb_bool __MIDI_PlayFromMemory(const char *buffer, size_t bufferSize)
{
    static auto isMIDIAvailable = false;
    static auto isMIDIAvailableChecked = false;

    // If initial detection failed then don't bother
    if (isMIDIAvailableChecked && !isMIDIAvailable)
        return QB_FALSE;

    // if we have not tried MIDI detection then attempt it and set the detection flag
    if (!isMIDIAvailable)
    {
        isMIDIAvailableChecked = true;

        auto merr = midiStreamOpen(&hMIDIStream, &MIDIDevice, (DWORD)1, (DWORD_PTR)MIDIProc, (DWORD_PTR)0, CALLBACK_FUNCTION);
        if (merr != MMSYSERR_NOERROR)
        {
            midiStreamClose(hMIDIStream);
            hMIDIStream = nullptr;
            isMIDIAvailable = false;
            return QB_FALSE;
        }

        // The MIDI steam will be closed by the if block below
        isMIDIAvailable = true;
    }

    // Close any MIDI streams being used
    if (hMIDIStream)
    {
        midiStreamStop(hMIDIStream);
        midiStreamClose(hMIDIStream);
        hMIDIStream = nullptr;
    }

    // Free any playing song
    if (pMIDISong)
    {
        if (pMIDISong->NewEvents)
            free(pMIDISong->NewEvents);
        free(pMIDISong);
        pMIDISong = nullptr;
    }

    // Open the MIDI file only if filename is not NULL
    if (!buffer || !bufferSize)
    {
        return QB_TRUE; // Shutdown successfull
    }
    else
    {
        auto f = MemFile_Create(reinterpret_cast<uintptr_t>(buffer), bufferSize);
        if (!f)
        {
            return QB_FALSE;
        }

        pMIDISong = (MIDISong *)malloc(sizeof(MIDISong));
        if (!pMIDISong)
        {
            MemFile_Destroy(f);
            return QB_FALSE;
        }
        ZERO_OBJECT(pMIDISong);

        /* Attempt to load the midi file */
        MIDIEvent *evntlist = nullptr;
        evntlist = MIDICreateEventList(f, &pMIDISong->ppqn);
        if (!evntlist)
        {
            free(pMIDISong);
            pMIDISong = nullptr;
            MemFile_Destroy(f);
            return QB_FALSE;
        }

        MIDIToStream(evntlist);
        MIDIFreeEventList(evntlist);

        auto merr = midiStreamOpen(&hMIDIStream, &MIDIDevice, (DWORD)1, (DWORD_PTR)MIDIProc, (DWORD_PTR)0, CALLBACK_FUNCTION);
        if (merr != MMSYSERR_NOERROR)
        {
            hMIDIStream = nullptr;
            free(pMIDISong);
            pMIDISong = nullptr;
            MemFile_Destroy(f);
            return QB_FALSE;
        }

        pMIDISong->NewPos = 0;
        pMIDISong->MusicPlaying = true;
        pMIDISong->Loops = 0; // play only once by default
        MIDIPROPTIMEDIV mptd = {};
        mptd.cbStruct = sizeof(MIDIPROPTIMEDIV);
        mptd.dwTimeDiv = pMIDISong->ppqn;
        merr = midiStreamProperty(hMIDIStream, (LPBYTE)&mptd, MIDIPROP_SET | MIDIPROP_TIMEDIV);
        MIDIBlockOut();
        merr = midiStreamRestart(hMIDIStream);
        MemFile_Destroy(f);

        return QB_TRUE;
    }

    return QB_FALSE;
}

/// @brief Stops playback, unloads the MIDI file from memory and frees any allocated resource
void MIDI_Stop()
{
    __MIDI_PlayFromMemory(nullptr, 0);
}

/// <summary>
/// Checks if a MIDI song is playing
/// </summary>
/// <returns>True if playing. False otherwise</returns>
inline qb_bool MIDI_IsPlaying()
{
    return pMIDISong && pMIDISong->MusicPlaying ? QB_TRUE : QB_FALSE;
}

/// @brief Sets a MIDI tune to loop
/// @param loops The number of times the playback should loop. Playback can be looped forever by specifying a negative number (like QB_TRUE)
void MIDI_Loop(int32_t loops)
{
    if (pMIDISong)
        pMIDISong->Loops = loops;
}

/// @brief Returns true if the file is set to loop forever or is still looping
/// @return QB_TRUE if looping, QB_FALSE otherwise
inline qb_bool MIDI_IsLooping()
{
    return pMIDISong && pMIDISong->Loops ? QB_TRUE : QB_FALSE;
}

/// @brief Pauses or unpauses MIDI playback
/// @param pause True to pause or False to unpause
void MIDI_Pause(int8_t state)
{
    if (hMIDIStream && pMIDISong)
    {
        if (state)
        {
            midiStreamPause(hMIDIStream);
            pMIDISong->MusicPaused = true;
        }
        else
        {
            midiStreamRestart(hMIDIStream);
            pMIDISong->MusicPaused = false;
        }
    }
}

/// @brief Returns true if MIDI playback is paused
/// @return QB_TRUE if paused, QB_FALSE otherwise
inline qb_bool MIDI_IsPaused()
{
    return pMIDISong && pMIDISong->MusicPlaying && !pMIDISong->MusicPaused ? QB_FALSE : QB_TRUE;
}

/// @brief Set the MIDI playback volume
/// @param volume A floating point value (0.0 to 1.0)
void MIDI_SetVolume(float volume)
{
    if (hMIDIStream)
    {
        volume = ClampSingle(volume, 0.0f, 1.0f);
        auto calcVolume = int(65535.0f * volume);
        midiOutSetVolume((HMIDIOUT)hMIDIStream, MAKELONG(calcVolume, calcVolume));
    }
}

/// @brief Returns the current MIDI volume
/// @return A floating point value (0.0 to 1.0)
inline float MIDI_GetVolume()
{
    DWORD dwVolume = 0xFFFF;

    if (hMIDIStream)
    {
        if (midiOutGetVolume((HMIDIOUT)hMIDIStream, &dwVolume) == MMSYSERR_NOERROR)
            dwVolume = LOWORD(dwVolume);
        else
            dwVolume = 0xFFFF;
    }

    return (float)dwVolume / 65535.0f;
}

/// @brief This is a quick and dirty function to play simple single sounds asynchronously and can be great for playing looping music.
/// This can playback WAV files that use compressed audio using Windows ACM codecs!
/// @param buffer A pointer to .WAV file in memory
/// @param loop If this is true the sound loops forever until it is stopped
/// @return QB_TRUE if the call succeeds. QB_FALSE otherwise
inline qb_bool Sound_PlayFromMemory(const char *buffer, int8_t loop)
{
    return (IS_STRING_EMPTY(buffer) ? PlaySoundA(NULL, NULL, 0) : PlaySoundA(buffer, NULL, SND_ASYNC | SND_MEMORY | (loop ? SND_LOOP : 0) | SND_NODEFAULT)) ? QB_TRUE : QB_FALSE;
}

/// @brief Stops any playing sound
inline void Sound_Stop()
{
    PlaySoundA(NULL, NULL, 0);
}
