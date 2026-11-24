# Third-party components

## LibGraph-2.0 Revived

- Release: v2.0.9; embedded library revision: 69 (LibStub minor 92069).
- Project: https://www.curseforge.com/wow/addons/libgraph-2-0-revived
- Source: https://www.curseforge.com/wow/addons/libgraph-2-0-revived/files/9095534
- Authors: Cryect, Xinhuan; maintained by Pimptasty.
- Imported from the user-provided release archive, without source or texture changes.
- Location: `Libs/LibGraph-2.0/`.
- The Lua file and all accompanying `.tga` files must remain in the same directory.
- Original licensing notice: `Libs/LibGraph-2.0/LICENSE`.

The supplied license reserves the original code and textures to their authors and
licenses only later modifications under MIT. No blanket redistribution grant for
the original portion was found in the supplied archive. Inclusion was explicitly
requested by the project owner; this does not change the supplied license terms.
The project's GPL-2.0-or-later notice applies to original FrameNet Graph code.

Only the drawing library is loaded by our TOC. The standalone library TOCs, Ace3,
VersionCheck, demos, and development files are not included as separate addons.

## LibStub

- Version: 1.0, minor 2, supplied with LibGraph-2.0 Revived v2.0.9.
- Location: `Libs/LibStub/LibStub.lua`.
- Public domain according to the source header and the supplied LibGraph license.
- Authors: Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke.

## Minimap launcher dependencies

Sources are embedded without changes. Load order: LibStub, CallbackHandler, LibDataBroker,
LibDBIcon. The complete Ace3 framework is not included.

| Component | Version | Source |
|---|---|---|
| CallbackHandler-1.0 | minor 8 | https://github.com/WoWUIDev/Ace3/tree/master/CallbackHandler-1.0 |
| LibDataBroker-1.1 | minor 4 | https://github.com/tekkub/libdatabroker-1-1 |
| LibDBIcon-1.0 | v12.1.2, minor 57 | https://repos.wowace.com/wow/libdbicon-1-0/tags/v12.1.2/ |

CallbackHandler's Ace3 license is preserved in `Libs/CallbackHandler-1.0/LICENSE.txt`.
LibDBIcon declares the same Ace3 Style BSD terms at
https://www.wowace.com/project/15552/license; these are preserved in
`Libs/LibDBIcon-1.0/LICENSE.txt` (the tag has no separate license file).
LibDataBroker has no separate license file in its source repository. Its README is
preserved; the author's embedding instructions are at
https://www.wowace.com/projects/libdatabroker-1-1.

SHA-256 of the downloaded Lua sources:

```text
CallbackHandler-1.0: 24f7342068e0d1b8d38ee1b8c7ceeea625bea079a01f0222e341660c7b104432
LibDataBroker-1.1:  f3d4758f2060215492c9764b1d7dc2a336826d4cd253cd54ff9ff7c6d78f04e2
LibDBIcon-1.0:     cafa823dfb9f216eb476af4bcd2fad4c25c718f39b7565fa1c924dbebac41f91
```

The launcher and addon-list icon use project artwork supplied by the project owner.
See [artwork sources](Artwork/README.md).
