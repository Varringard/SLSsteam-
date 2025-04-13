#pragma once

#include "libmem/libmem.h"

namespace Patterns
{
	constexpr lm_string_t LogSteamPipeCall = "E8 ? ? ? ? 83 C4 10 85 FF 74 ? 8B 07 83 EC 04 FF B5 ? ? ? ? FF B5 ? ? ? ? 57 FF 10 83 C4 10 8D 45 ? 83 EC 04 89 F3 6A 04 50 FF 75"; //Relative

	constexpr lm_string_t CheckAppOwnership = "E8 ? ? ? ? 88 45 ? 83 C4 10 84 C0 0F 84 ? ? ? ? 8B 45 ? 80 7D ? 00"; //Relative

	//Family sharing
	constexpr lm_string_t FamilyGroupRunningApp = "E8 ? ? ? ? 83 C4 10 83 EC 08 C7 46 ? 01 00 00 00 C6 46 ? 01 56 57 E8 ? ? ? ? 83 C4 1C B8 01 00 00 00 5B 5E 5F 5D C3 ? ? ? ? ? ? ? 83 EC 04"; //Relative

	//Seems to have been removed April 1.
	//constexpr lm_string_t SharedLibraryLockStatus = "E8 ? ? ? ? 05 3B CE A9 01"; //Unused atm
	//constexpr lm_string_t SharedLibraryLockChanged = "E8 ? ? ? ? 8D 83 ? ? ? ? 83 C4 0C 56 50 8D 83 ? ? ? ? 50 E8 ? ? ? ? 8B 45"; //Relative, unused ?
	constexpr lm_string_t StopPlayingBorrowedApp = "55 89 E5 57 56 E8 ? ? ? ? 81 C6 C2 94 D6 01";

	//Interfaces
	constexpr lm_string_t IClientAppManager_PipeLoop = "E8 ? ? ? ? 83 C4 10 E9 ? ? ? ? 8B 4D ? 85 C9 0F 84 ? ? ? ? 8B 5D ? 83 EC 0C 8B 03 53 FF 90 ? ? ? ? 83 C4 10 85 C0 0F 84 ? ? ? ? FF 75 ? 05 94 18 00 00 89 F3 FF 75 ? FF 75 ? 50 E8 ? ? ? ? 83 C4 10 E9 ? ? ? ? E8"; //Relative
	constexpr lm_string_t IClientApps_PipeLoop = "E8 ? ? ? ? 83 C4 10 E9 ? ? ? ? 8B 4D ? 85 C9 0F 84 ? ? ? ? 8B 5D ? 83 EC 0C 8B 03 53 FF 90 ? ? ? ? 83 C4 10 85 C0 0F 84 ? ? ? ? FF 75 ? 05 9C 25 00 00"; //Relative

	constexpr lm_string_t IClientUser_PipeLoop = "E8 ? ? ? ? 83 C4 10 E9 ? ? ? ? E8 ? ? ? ? FF 75"; //Relative
	constexpr lm_string_t GetSubscribedApps = "E8 ? ? ? ? 89 C6 83 C4 10 85 C0 0F 84 ? ? ? ? 8B 9D ? ? ? ? 39 D8"; //Relative
}

