---
title: World Partition Guide
author: Yohiro
date: 2023-05-19
categories: [Unreal Engine, World Partition]
tags: [engine, level, streaming, unrealengine]
render_with_liquid: false
img_path: /assets/images/WP/
---

World Building Guide
This guide provides per-feature definitions, subjects to master, good practices and pitfalls,
limitations, use cases specific to world building with Unreal’s world partition system. Note: all
provided Roadmap/Future Developments are subject to change (see World Building Roadmap).
Features List
World Partition
World Partition is an automatic data management and distance-based level streaming system
that provides a complete solution for large world management. The system removes the
previous need to divide large levels into sublevels by storing your world in a single persistent
level separated into grid cells, and provides you with an automatic streaming system to load and
unload those cells based on distance from a streaming source.
OFPA - One File Per Actor
One File Per Actor (OFPA) reduces overlap between users by saving data for instances of
Actors in external files, removing the need to save the main Level file when making changes to
its Actors.
Level Instances and Packed Level Actors
Level Instance & Packed Level Actors are both “non-destructive” workflows that allow instancing
of content within the same world with their respective use cases and goal.
Data Layers
Data Layers is a system designed to conditionally load world data for both runtime and editing.
Actors and World Partition define which streaming logic (Is Spatially Loaded, Runtime Grid and
Enable Streaming), Data Layers are acting as a filter for level streaming.
HLODs - Hierarchical Level Of Detail
Hierarchical Level Of Detail (HLODs) are a visual representation of a group of actors that is
meant to replace those actors when viewed from a considerable distance and is automatically
generated.
Editors and UX
Editors, Outliners and UX specific to World Partition.
Data streaming outside of World Partition
Streaming of data can be handled by other systems outside of World Partition depending on the
features used and platforms. Nanite and Texture streaming are the two most important content
streaming systems outside of World Partition.
Features Details
World Partition
Useful links
Official public documentation:
https://docs.unrealengine.com/5.1/en-US/world-partition-in-unreal-engine/
Subjects to master
World building, automatic streaming, grid setup and promotion, actor streaming setup,
streaming sources, datalayers, HLODs, level instances, packed level actors, OFPA,
commandlet, cook build, server streaming, generate streaming
Definition
World Partition is an automatic data management and distance-based level streaming system
that provides a complete solution for large world management. The system removes the
previous need to divide large levels into sublevels by storing your world in a single persistent
level separated into grid cells, and provides you with an automatic streaming system to load and
unload those cells based on distance from a streaming source.
Important changes in 5.1
● Actor promotion
A new option (disabled by default, cvar) has been added to reduce actors up-promotion
and the issue where partitioned actors would end up persistent when crossing the grid
center axis is fixed.
○ Actors: Additional check for AABB < grid cell size (2D), if true the actor will be
assigned to the grid cell using its pivot position.
○ Partitioned actors: (Landscape proxies, Foliage actors, etc) uses pivot.
○ CVAR:
■ wp.Runtime.RuntimeSpatialHashPlaceSmallActorsUsingLocation=1
(limited to the base grid level, regular promotion occurs if the object fails
this test)
● Grid centering changes
Optional grid offset can be used where grid levels are centered on a cell for each grid
level instead of the same grid origin for all levels.
○ CVARs:
wp.Runtime.RuntimeSpatialHashUseAlignedGridLevels=0
wp.Runtime.RuntimeSpatialHashSnapNonAlignedGridLevelsToLowerLevels=0
● Editor grid removed, Locations and Regions introduced
Editor grid concept was entirely removed from the editor and WP in 5.1. It was creating
too much confusion and the grid itself was preventing us from scaling up to worlds larger
than the Matrix Awaken demo (memory used in editor).
Basic Location Volumes actors can be placed in the world to identify persistent regions
and the world partition editor now works with these Locations. The editor also allows
transient 2d regions selection and loading allowing you to work in levels without any
location volumes. This is an introduction toward the development of the bookmarks and
locations system.
● Per-actor grid placement option removed
No more options in the actor properties to decide if it should use bounds, pivot or center
point to define in which streaming cell the actor will be part of, we use bounds unless the
new actor promotion cvars above are enabled. IsSpatiallyLoaded and the grid to use are
now the only available options within the actors’ properties.
● Fortnite CH4 using World Partition
○ Shipped WP on all platforms, performance, QoL and overall stability
improvements across the board. Everything available in 5.1.
● PlayerController base class can now auto register itself as a StreamingSource.
Good practices
● Grid setup
○ Start your world production with a single grid, the less amount of grid in the end
the better.
○ Grid size and Loading range should be based on gameplay, physics and actor
counts estimation/requirements AND re-evaluated/adjusted as content is added
to the world from profiling.
○ Consider Nanite and Texture streaming for content.
○ Consider HLODs setups (instanced layer, nanite enabled, merged, streaming).
● Use Level Instances and Packed Level Actors, combine them.
○ Level instances are there to allow sub-level editing in context and multiple
instances of the same data to be easily placed within the world. In most cases
(OFPA enabled), Level Instances are broken down and all of their contained
actors, including nested level instances actors, are moved into the persistent
world grid during generate streaming which is done at PIE and COOK.
○ Packed Level Actors are great to package visual-only content into a single
actor. Reduces actor count and provides a faster path for GPU.
○ Both are orthogonal to each other, Level Instances can be nested in other Level
Instances creating a hierarchy. Packed Level Actors can be placed just as any
actors within Level Instances.
○ Packed Level Actor is a single actor and its bounds will determine in what cell
this actor gets streamed in from. Take this into account to determine granularity.
● Work smart, load what you need.
○ In complex, heavy worlds such as the Matrix Awaken demo/big city sample,
requires you to load in editor only areas you are working in. We do not support
automatic streaming in the editor at the moment.
● Use streaming sources components
○ The streaming in game depends on streaming sources. By the default the player
controller is a streaming source but streaming source components can be added
to any actors (such as the camera for a cinematic) to load content elsewhere or
even preload for a seamless in-game cinematic at another location.
● Spacing
○ During conception/preprod, thematise and layout heavy/unique content according
to target loading range. Space can be your friend, use it wisely and creatively.
● Have a streaming and content champion(s) and invest in profiling automatisation
○ A tech artist, tech director that monitors world walkthrough runs, content budget
and validation, brings in as much automation as possible in that area based on
your game and content specifications.
○ Replays are extremely useful to run performance A/B comparisons and profiling
changes with a repeatable walkthrough. Using replays for profiling should be
integrated early in production.
Pitfalls
● Creating new Grids and runtime Data Layers for widely distributed content
○ Each cell of each grid, containing at least one actor, produces a streaming level.
Additionally, a streaming level is also created for each unique runtime data layer
combination found on actors in that grid cell. The overall number of streaming
levels at any given place has an impact on performance that should be
considered.
I.e
● Creating multiple grids or runtime data layers per asset type like a
grid for trees, FX, all lights, small rocks, large rocks, within the
same forest world.
● Using runtime data layers for editing only purpose with no intent of
changing the data layer state at runtime.
○ This is very context dependent on the platform, content, setup, … and not
forbidden.
■ Ultimately, the balance between the overall benefits of adding a new
grid or runtime data layer over the potential impact on streaming
performance should be tested and validated.
■ Also, adding a grid or runtime datalayers for very localized content has
very little impact overall and can be safely used.
○ Example cases:
■ Actors A, B, C are SpatiallyLoaded and set to be in Main grid, bounds are
within a cell.
● Only 1 streaming level is created for the grid cell as it contains
actors A, B C
■ Actors A, B, C are SpatiallyLoaded and set to be in Main grid, bounds are
within a cell, C is data layered on a single runtime data layer.
● 2 streaming levels are created for the grid cell, 1 for A and B and 1
one for C as it is on a runtime data layer
■ Actors A, B, C are SpatiallyLoaded and set to be their own respective
grid, bounds are within a cell.
● 3 streaming levels are created, 1 for each cell of each grid
containing an actor
■ Actors A, B, C are SpatiallyLoaded and all set to be their own respective
grid, bounds are within a cell, actors D, E, F are copies of A, B, C but data
layered on a single runtime data layer.
● 6 streaming levels are created, 1 for each cell containing a
non-data layered actor and 1 for each cell of each grid containing
an actor with a runtime data layer.
● Scene/Data Layer Organization
○ The scene outliner and editor data layers can overlap in terms of UX and data
organization and become problematic in dense large worlds. Prepare your scene
structure and enforce it. Use pre-configured level templates. Use Actor editor
context when possible. Use Validation when required. Keep editor data layers for
larger or specific working sets.
● Actors bounds
○ Since actor bounds are important to define which grid level it will result in, large
actor bounds can lead to content being promoted up to persistent which defies
the automatic streaming purpose. Validation and automation can be used to
monitor this issue.
● Micro management of grid promotion
○ After understanding grid promotion, the usual reaction is to try to control it by
micro-managing placement, bounds, object size, etc. Don’t micromanage but do
monitoring and build systems with it in mind.
Limitations
● Grids belongs to the persistent world
○ We only support a single streaming hash with multiple grids set in the persistent
level.
● “2d” streaming hash
○ We only support the “2d” streaming hash. The plan is to introduce different
streaming hash (3d & linear) and support mixing, additional streaming hash can
be coded per project needs if desired.
● Reconfiguring grid VS partitioned actors
○ Partitioned actors such as Landscape and Foliage are sliced on a configurable
grid size and created following the defined size as needed (i.e while painting
foliage or adding landscape components). The resulting partitioned actors are not
updated when reconfiguring the world’s streaming grid; a commandlet is
available to recreate partitioned actors when that is required.
■ Landscape Builder is not yet implemented, but planned for 5.2.
● Manual loading in editor
○ We do not support automatic camera-based loading in the editor at the moment.
Content in a world must be loaded using the world partition editor through
transient region selection and location volumes actors placed in the world.
Loading in editor is not limited within pools/buffers (compared to nanite or texture
streaming), which can lead to out of memory crashes.
● Runtime constraints
○ No grid creation/changes at runtime, generate streaming is done every time you
hit PIE or Cook a build.
○ No level creation/injection at runtime
■ Coming content bundle / game feature plugin development supports
injecting specific actors at runtime.
■ Level instancing is possible through code.
○ Spawned actors are persistent, child actors are dependant of their parent
loading.
○ Referencing spatially loaded actors from persistent actors is forbidden.
● Garbage Collection
○ Unloaded content will get garbage collected at a defined fixed interval or when a
specific number of cells has been unloaded in order to better distribute its cost
over time.
● One File Per Actor (OFPA)
○ WP is tied with OFPA. Lots of external actor files and source control load needs
to be considered.
● Hot reload
○ While Unreal supports hot reload of assets, external actors found in WP levels
can not be hot reloaded from revert/sync operations. The WP level must be
closed to reload external actors.
● Dynamic lighting only
○ WP does not support static lighting baking features.
● Persistency
○ No native persistence support at the moment.
● Server Streaming
○ Naive approach only.
Current use cases/Scenarios
Fortnite Chapter 4
● Map size: 2km x 2km.
● # of actors: ~100k.
● Single grid : 128m cell size, 256m loading range (range modified per-platform for low
end).
● 2 HLODs setups.
○ HLODs for buildings (2 layers)
■ HLOD0 special merged mesh with destruction support, 256m cells, 512m
range, Spatially loaded.
■ HLOD1 simplified mesh, 512m cells, 2048m range, Spatially loaded.
○ HLODs for trees (1 layer)
■ Instanced layer for trees imposters, always loaded.
● Level Instances: all POIs and Locations.
● Datalayers:
○ 4 specific to lobby/startup island.
○ 1 per event/season changes.
● Server: everything loaded.
○ Server streaming is used in PIE to improve developers iteration speed and
workflows.
● Landscape: always loaded.
● Platforms: all of them from mobile to switch to current gen nanite-enabled platforms.
● Packed Level Actors: none.
The Matrix Awaken demo - UE5
● Map size: 4km x 4km.
● # of actors: ~107.
● Single grid : 128m cell size, 128m loading range.
● HLODs setup with 2 layers:
○ HLOD0 Nanite-Enabled instanced layer, 256m cells, 768m range, Spatially
Loaded
○ HLOD1 Simplified mesh, 256m cells, always loaded
● Procedurally constructed with Houdini and Rule Processor plugin in UE, hero locations
handcrafted.
● Packed Level Actors and procedurally generated actors with ISM (equivalent to PLA) are
used for all buildings, roads, props.
● Datalayers, (35 runtime, 21 editor)
○ Used for cinematics and gameplay content.
○ Used for assets on roof tops and below highway.
● Landscape: none.
Ancient Game - UE5 Preview
● Map size: 2km x 2km.
● # of actors: ~14k actors.
● Single grid : 64m cell size, 64m loading range
● HLODs setup with 1 layer:
○ HLOD0 instanced, always loaded
● Packed Level Actors: used for rocks grouping with custom support for collision merging.
● Datalayers, (2 runtime, 1 editor).
● Landscape: none.
Roadmap/Future Developments
● Support all verticals for all domains.
● Support all types of world structures and allow mixing between them.
● Reduce grid promotion in 2d and 3d grid hash.
● Content Bundles/Game Features Plugin.
● Server Streaming.
● Landscape Builder.
● Improve debugging, monitoring and profiling of WP through heatmaps and viewport
visualization.
● Support hot reload.
● Support static lighting.
● Continued UX polish.
● In-editor camera streaming (long term).
Useful Commands
● wp.Runtime.ToggleDrawRuntimeHash2D or 3D : toggles streaming grid debug
display.
● wp.Runtime.OverrideRuntimeSpatialHashLoadingRange -grid=[index]
-range=[DesiredValue] : overrides loading range.
● wp.runtime.hlod : toggles HLODs display.
OFPA - One File Per Actor
Useful links
Official public documentation:
https://docs.unrealengine.com/5.1/en-US/one-file-per-actor-in-unreal-engine/
Subjects to master
Level and actor setups, Source Control, External Actors and GUIDs, Unsaved,
Uncontrolled CL
Definition
One File Per Actor (OFPA) reduces overlap between users by saving data for instances of
Actors in external files, removing the need to save the main Level file when making changes to
its Actors. These External Actors are stored in the project’s content folder but are not accessible
from the editor content browser. OFPA also includes Scene Outliner folders as External Objects,
also in the project’s content folder, allowing users to move, rename, delete without having to
checkout all actors and the world.
Important changes in 5.1
● Source Control UX
○ Multiple improvements were made to the source control - view changelist window
to help users filter, sort, manage their changelist with tons of external actors and
assets files.
○ Source control column in the scene outliner displays the status of each actors as
they appear (async).
○ Conflicting status warnings are now displayed with the Unsaved items button.
● Uncontrolled CL
○ Allows tracking within Unreal of all writable (uncontrolled) files within your project,
giving you full visibility on your local changes as well as adding new source
control interactions. It brings the possibility to track local edits in multiple
uncontrolled changelists that can be individually moved back to controlled
(checked out) or reverted whenever needed. In daily usage this prevents locking
assets for testing or debugging purposes and further reduces file contention. By
having clear knowledge of these file states within Unreal, you can manage them
individually without ever having to go through tedious clean up and reconcile
operations in your external source control client.
○ Activated by default in UE5.1.
● Unsaved Items
○ All dirtied/unsaved files (external actors, assets, worlds, etc) are tracked and now
displayed with the Unsaved Items button in the main editor window bottom bar. It
allows users to know when and how many files need to be saved under the
World Partition context.
○ The button is a shortcut to Choose File to Save Dialog.
○ Source Control status on dirty is requested. All source control conflicts (already
checked out, not at latest revision, deleted, etc) appear immediately in the
Unsaved items button and a toast pop-up warning.
● Async source control operations & Perforce performance and usability fixes
○ Multiple source control operations in scene outliner, view changelist window, etc
have been moved to async to avoid blocking the editor.
○ Perforce fixed 2 major issues with edge servers (22.1.latest or + from Perforce).
■ Major performance issues when editing and deleting multiple files.
■ Edge vs commit/proxies files status not matching.
● Actor Descriptors
○ Can get ActorDesc to build different utilities in the editor.
■ UWorldPartitionBlueprintLibrary utility library to access ActorDescs
through BP.
○ ActorDesc currently contains: GUID, Class, Name, Label, Bounds, Runtime Grid,
IsSpatiallyLoaded, ActorIsEditorOnly, Actor Package, Path, Data Layers, HLOD
layer, Actor References, Tags, Folder, Parent Actor, Content Bundle and Custom
Properties.
○ Licensees can extend ActorDesc
■ AActor::GetActorDescProperties and
AActorComponent::GetActorDescProperties
Good practices
● Use Unreal’s Source Control / View Changelist
○ We heavily encourage all World Partition users to move to using Unreal source
control integration for check outs, editing changelists and submitting all content
through the View Changelist window. Projects should enforce users to go through
Unreal when using WP.
○ Why?
■ External Actors files in WP are named with GUIDs and sorted
automatically based on these in a specific folder structure, which makes
them impossible to identify correctly within an external source control
application such a P4V. Unreal’s view changelist window displays the
actor display name, type and path, allowing you to properly filter, sort and
manage these files.
■ Uncontrolled CL is a powerful tool which is not available outside Unreal.
■ Validation is done at submit (or at user’s request) on the changelist’s
content preventing users from introducing data issues. The validation can
be extended in code for specific project needs.
■ Much better user experience to stay within the application and navigate
from CL to actors or content immediately for visual validation.
● Use Uncontrolled CL
○ See files you edited and made writable OR added during source control outage.
○ Use it to work locally, work over a locked file, move edits to Uncontrolled to allow
others to unshelve your CL.
○ Clean up your workspace of local ghost files.
○ Move back edits and adds from Uncontrolled CLs to your Source Control CLs
when ready.
○ Programmers should always use Uncontrolled CL to avoid blocking binary
content files when debugging or testing.
● Create custom submit Validation if needed
○ Submit validation has been implemented and can be extended in code by
projects who would like to enforce specific validation to their production. Core
validations are already done on submit such as references issues, missing files in
CLs, etc
Pitfalls
● Users’ first reaction with managing individual files
○ Most Unreal users' first reaction to OFPA is that they don’t want to manage a
large changelist AND they are worried that other co-workers will work in the same
area in parallel. After getting used to it, it quickly becomes less of an issue and
the benefits are appreciated.
■ Embrace working in parallel, it's all about removing file contention.
■ Problematic changes can be more easily identified, isolated and reverted
or fixed.
■ Always know precisely what you changed, no more blind level save and
submit with undesired edits/adds/deletes.
○ Bunch of minor changes like scene outliner source control column, the unsaved
items and column, the source control conflicting state warnings and the save
dialog have been added or improved on to help users with OFPA.
● Using P4V with external actors
○ For all reasons listed above in the good practices, using P4V to submit content
should be avoided, discouraged and even prohibited in production.
● Branching, merges, duplicates and file amount
○ OFPA can add a burden on server load, syncing and when creating branches
especially on large teams and large dense worlds. Needs to be monitored with
data managers.
○ Large multi studio, multi users team should consider proxies and edge servers to
distribute load.
Limitations
● Beautification of GUIDs only available in UE
○ GUIDs can only be transformed to their display names within Unreal.
○ GUIDs can be filtered in the scene outliner, helpful when having to identify a
specific file from perforce or explorer.
○ Actor path can also be copied from the world outliner and pasted in P4V to find
the file when needed.
● Non-OFPA VS OFPA Level Instances
○ Streaming behavior is different between non-OFPA and OFPA-enabled Level
Instances.
■ OFPA-enabled = on generate streaming (pie and cook) level instances
content is broken down into the persistent world and assigned to its
streaming grid. Level Instances do not exist at runtime.
■ Non-OFPA = the level instance is kept during generate streaming and is
considered as one actor that will stream in as a block when the grid cell
level containing the level instances is loaded.
● Accessing unloaded actors
○ Tools and data driven utilities will require you to get ActorDescs in order to find
GUIDs and load before interacting with them if needed. You can not access
actors without having the world loaded in the level editor.
● Locking
○ We do not have an actor locking system at the moment. This is a frequent
request to prevent users from editing external actors without permission without
having to check-out assets to prevent the edits.
● Discoverability of files status
○ A lot of improvements were done in 5.1 to give a faster feedback on file statuses
but we are also limited by source control performance and editor performance.
Enabling the source control column in the scene outliner and monitoring the
unsaved warnings over source control conflicts are the best ways for users to
discover if changes can be made or not.
Current use cases/Scenarios
● Fortnite Chapter 4
○ Single large world with ~100k external actors
○ Multi users around the world using a mix of commit, proxies and edges servers
all in parallel.
○ Multiple branches created holding the same content and amount of files
(cinematics, next release, next season, etc).
Roadmap/Future Developments
● Unsaved List in View Changelist .
● Scene Outliner filtering for unsaved, uncontrolled and modified.
● Locking actor system.
● One File Per Cell/Level/Area (reduce file management/quantity while trying to maintain
reduced file contention).
Level Instances and Packed Level Actors
Useful links
Official public documentation:
https://docs.unrealengine.com/5.1/en-US/level-instancing-in-unreal-engine/
Subjects to master
Definition of both LI and PLA, Blueprint Child Actors, Loading in Editor, Data layers
Instances
Definitions and Differences
Level Instance & Packed Level Actors are both “non-destructive” workflows that allow instancing
of content within the same world with their respective use cases and goal. LI and PLA are NOT
overridable prefabs.
Level Instance:
is a level-based workflow that facilitates world building by enabling instancing of levels,
through a reference into a level instance actor, as predefined sets of actors. It allows editing
them in context without exiting the world in which they are instanced in. Level instances
support hierarchical nesting of additional sublevels within a sublevel.
Level Instances should be OFPA-enabled when used in WP levels, which will automatically
break its content into the persistent world streaming grid levels on generate streaming (pie and
cook). Non-OFPA Level instances will be considered a single block in its own streaming level
which can lead to performance and streaming issues when used on large and complex data
structures.
LI Features:
+ Nested and Hierarchical Level Instances.
+ Edit in Context (always the original level, no per-instance data/edit supported).
+ Multiple Instances within the same World.
+ Embedded Mode (default) : Content pushed to the persistent world partition grid.
+ Level Streaming Mode: For non-OFPA levels.
+ Data Layers on the Level Instance Actor is propagated to its entire content.
+ Data Layers are supported on actors within Level Instances, the persistent world DL
Instances defines the states. (new 5.1).
LI Use Cases:
+ POI, houses, interiors, building floors, deco sets, villages, stand alone gameplay
setups, etc.
Packed Level Actor: outputs a single actor BP holding visual components exclusively
(static mesh, instanced static mesh and hierarchical static mesh) found on all actors contained
within its associated source level, everything else is discarded from the output. This output
is only processed within the editor and is triggered at creation and upon commit of editing in
context.
Packed Level Actors BPs are non-overridable and non-scriptable as they are recreated
entirely every time it gets updated.
PLA Features:
+ Outputs a Packed Level Actor BP with ONLY SM/ISM/HISM from the content.
+ Outputs a Level that is associated to the Packed Level Actor for non-destructive
editing.
+ Multiple instances, like any actor, within the same world.
+ Edit in Context (always the original level, no per-instance data/edit supported).
+ Data Layers on the Packed Level Actor only.
PLA Use Cases:
+ Static buildings (i.e The Matrix Awaken demo), Very dense visual-only setups with
multiple instances of the same models, etc.
Important changes in 5.1
● Supporting Data Layers on sub-actors
○ Data layers assigned to sub-actors within a Level Instance are now working since
the addition of DL Assets and Instances. If a sub-actor DL Asset is referenced by
a DL instance in the main persistent world it will end up in, the actor will keep its
data layering functionality and depend on the DL instance state in the world it is
in.
● Drag and drop support for LI
○ You can drag a level from the content browser into the world partition level and it
will automatically create a level instance actor with the reference to the level you
had selected.
● Bugs and UX fixes
Good practices
● Creating Production-Only playgrounds for constructing, editing and
previewing/reviewing Level Instances and Packed Level Actors.
○ It is a good idea to create an empty reference playground world which contains
the game’s world lighting, post-process, etc in which artists and designers can
craft level instances/packed level actors outside of the more complex and heavy
world context.
Pitfalls
● Creating world scale layers with Level Instances
○ As Level Instances are currently loaded in editor as a block non-asynchronously,
using a very large / world size level instance to nest all locations or other content
by type is often a very bad approach. Use smaller LIs per location and use
Editor-Only Datalayers when needed.
● Using Non-OFPA Level Instances
○ While this can be useful in some cases, using non-OFPA LIs results in creating a
separate streaming level for each instance in the world of each non-OFPA LI.
This can be problematic for streaming and performance.
○ We do not support HLOD generation for Non-OFPA level instances in the world.
● Using large Packed Level Actors
○ Since packed level actors are just actors with multiple ISM, HISM components,
creating PLA larger than streaming cell size can lead to streaming, performance
and memory issues. PLA should be kept under streaming cell size in most cases.
Limitations
● No overrides
○ Level Instances are referencing a source level. No overrides possible on actors
within a level instance. All edits made in context from any instance or within the
source level directly will apply to all.
○ Packed Level Actors are reconstructed every time they are updated which
prevents overrides.
● No Level Blueprint Support
○ As level instances are broken down during level streaming, we do not support
level blueprint on Level Instances.
● No referencing of actors within Level Instances
○ It is impossible to reference a sub-actor within a level instance from another actor
at a higher level.
● No partial and async loading in editor
○ Loading in editor will currently load all content in a level instance from the
intersection between the desired region to load and the BV of the level instance.
Loading of Level instances is not async.
○ Packed Level Actors are just single actors, loading in editor considers these just
like any other stand alone actors.
● No access to sub-actors to copy, edit, view, select, hide when not in edit mode
○ Sub-actors can not be edited, selected, copied, property view, editor visibility
changed outside of Edit in context at the moment.
○ For example, this can bring limitations when trying to hide parts of a Level
Instance while editing landscape in the main world or when trying to copy paste
from another Level Instance into the one being edited at the moment.
Current use cases/Scenarios
● Fortnite Chapter 4
○ All main locations built with Level Instances for each individual
buildings/houses/poi level of granularity.
○ Level Instances are single level deep in most cases.
○ No use of Packed Level Actors as FN gameplay requires each pieces to be
individual actors for destruction and interaction.
● The Matrix Awaken demo / City Sample
○ Packed Level Actors were used for Hero building hand-crafted outside of the
procedural world generation.
○ Packed Level Actors used to create pre-made rooftop assemblies then scattered
by the procedural system.
○ All procedural buildings, roads, rooftops meshes, props crunched into actors
made of ISM components (equivalent to PLA).
○ Collisions processed to have the base of the building a simple shape for the rest,
part of the procedural gen, in a separate actor. Only the base level had collision
per-module.
○ At the end of the production, the procedural generation was stopped and packed
level actors converted to ISM actors. Both were done to allow manual fixing onto
ISM with a special edit mode in the geometry tools to access instances
individually. Upon manual editing there was no possible way back to procedural
updates and original PLA without losing all fixes.
● Ancient Game - UE5 Preview
○ Packed Level Actors extended to support merged collision processing to optimize
physics/add to world cost when streaming levels.
Roadmap/Future Developments
● Async loading in editor.
● Read-only selection mode to access sub-actors (copy/paste, properties and visibility)
from outside of edit mode.
● Level Instance support for Game Features plugins.
● Custom HLOD support.
● UX Improvements (make unique/copy, context editing navigation, refresh PLA).
Data Layers
Useful links
Official public documentation:
https://docs.unrealengine.com/5.1/en-US/world-partition---data-layers-in-unreal-engine/
Subjects to master
DL Assets and Instances, DL Runtime and Editor types, DL States
Unloaded/Loaded/Activated and hierarchical min logic, OR logic between all DL,
Blueprint, Sequencer, Streaming sources, Level Instance, World Partition, Memory
management and streaming, HLODs
Definitions
Data Layers is a system designed to conditionally load world data for both runtime and editing.
Actors and World Partition define which streaming logic (Is Spatially Loaded, Runtime Grid and
Enable Streaming), Data Layers are acting as a filter for level streaming.
Each external actor owns which data layer(s) it is in, meaning that only the actors need to be
checked out when adding them to data layers in a world. Data layers instances on the other
hand are added to the WorldDataLayers actors which is required to add/remove or edit defaults
within each world.
Runtime:
+ Handle different scenarios.
+ Create variation within the same world.
+ Manage specific data for sequences, missions, game progression, events and
more.
+ Full HLODs support, creates a specific HLOD that will be following the Data
Layer state.
+ Is also an Editor data layer.
Runtime States:
Unloaded: Content is unloaded from memory and not visible.
Loaded: Content is loaded in memory and not visible.
Activated: Content is loaded in memory and visible.
Editor:
+ Organize your content.
+ Isolate data for better in-context work.
+ Preview runtime data layer content.
+ Editor only data layers are not accessible in PIE and Cooked builds.
Editor States:
IsInitiallyVisible: if the DL should be visible by default when loading the
world.
IsInitiallyLoaded: if the DL should be loaded by default when loading the
world.
Loaded: user toggle loading.
Visible: user toggle visibility.
Important changes in 5.1
● Datalayers as Assets and Instances
○ With the release of 5.1, Data Layers are now separate content assets referenced
in what we call data layers instances within the WorldDataLayers actor for each
world. In the previous release, data layers were unique per world embedded in
the WorldDataLayers actor found in every World Partition Level.
○ Data Layer assets define the type (editor or runtime) and the debug color.
○ Data Layer instances holds the reference to an asset and sets the default
editor/runtime states per world.
○ Allows:
■ Sharing the same data layer assets across multiple worlds within a
project.
■ Data layer support for actors in level instances.
■ Different default states per-world.
● Support for Level Instances
○ As mentioned above, with the arrival of Data Layer Assets and Instances, actors
within a level instance that have data layers assets will now be working if the
main world holds data layer instances of the same assets and their states will be
applied accordingly.
○ In edit mode, you can preview and promote level instance specific datalayers to
the main world in order to fully support them in the current world.
● Actor Editor Context support
○ With the addition of the actor editor context in the Level Editor. You can mark as
Current, any number of data layers instances in your world. All actors added with
the editor context active will automatically receive the data layer(s) that were set
as Current.
Good practices
● Use Editor-Only Data Layers to isolate content
○ Using editor data layers, you can easily isolate working set content for things
such as cinematics and specific gameplay sequences.
○ Allow separation of automatic/procedural data or specific types such as
Buildings/Roads/Forest etc.
● Pre-loading and sequencer
○ Using sequencer data layer tracks, you can pre-roll and set different states so
your data layers are ready with all their content loaded when the playback starts
in-game.
● Owner for Data Layers and Project wide Data Layers
○ It is best to have a technical owner on the production for project wide data layers
and structure.
○ When possible, productions should pre-define data layers assets that matches
their project structures and goals.
■ i.e. Missions, Events, Game Progression, Work Types, etc.
● Optims
○ In some specific cases, data layers can be used to reduce content during specific
sequences or gameplay that would not require parts of the worlds.
○ Similarly, data layers can be used to reduce content specific platforms in order to
save memory and performance.
Pitfalls
● Quantity of Data Layers
○ As mentioned above, a new unique streaming level is created for every runtime
data layer unique combination assigned to actors within a grid cell. Runtime data
layer creation and assignment should be monitored closely to prevent widely
distributed content using multiple runtime data layers which could degrade
streaming performance.
○ Using runtime datalayers for very localized content has very little impact overall
and can be safely used.
■ i.e. using a runtime data layer per quest, using a runtime data layer per
theme (Halloween, Christmas, etc.) or any other very localized content
setups can all be safely used and are totally fine.
● Combination of multiple data layers on actors
○ Similar to the previous point, each unique combination of data layers creates
another streaming level per grid cell for actors with the same configuration; this
can also result in streaming performance issues by having more streaming levels
to handle at runtime.
● Data Layers and streaming misconceptions
○ Actors’ IsSpatiallyLoaded, Runtime Grid settings remain the source for defining in
which streaming level they will be in for the given data layers assigned to them.
Setting the Activated state on a data layer will effectively load and activate the
top most level (non-spatially loaded actors) AND the streaming levels overlapping
the streaming sources based on their respective grid loading range.
■ This means that activating a data layer does not mean that all of its
content will be loaded immediately, streaming still needs to be taken
into account and actors/grids/loading ranges/streaming sources
configured properly.
● Loading too much stuff with data layers
○ Streaming an entirely new environment with data layers can be achieved but at
the cost of loading the equivalent of a new level. This can be fully acceptable if
the time to load such an amount of content is planned and included in the
conception of the level, such as preloading the assets during first load or hiding
transition with a cinematic or movie, or happening in a cheaper region of the
world. Be careful, streaming still needs to occur.
Limitations
● OR logic
○ Both in runtime and in editor, data layers logical operation is OR.
■ Actors will be loaded as soon as one of its data layers is loaded or active.
● Hierarchical and minimum logic
○ In a data layer hierarchy, a min logic is applied with the state of the parent data
layer, where unloaded (0), Loaded (1) and Activated (2).
○ Editor-only data layers can NOT be child of Runtime Data Layers, the opposite
works.
● WorldDataLayers actor
○ Data layers instances are added to the WorldDataLayers actor which is required
to add/remove or edit defaults within each world. This actor is an external actor
file, frequently manipulating which data layers instances in a world can result in
contention and conflict over that specific file.
Current use cases/Scenarios
● Ancient Game
○ 2 runtime (one which updates the entire world to a new dark world).
○ 1 editor.
● The Matrix Awaken demo
○ 35 Runtime.
○ 32 Editor:
■ Sequence and gameplay content streaming and unloading.
■ Sequence specific optims (under highways, etc).
■ All-Platforms optims (rooftops activated in drone only).
■ Multiple editor-only working set for artists and procedural content.
● Fortnite Chapter 4
○ 4 runtime specific to lobby/startup island covering a small area of the world.
○ 1 runtime per event/season changes:
■ Used in cinematics production workflows to apply worlds changes
per-shot
■ Used in test worlds to layer different configurations to test with
Roadmap/Future Developments
● Can specify a custom DataLayerLoadingPolicy to override the default OR behavior used
by the Data Layer "Editor Is Loaded" flag (5.2 - done).
Useful Commands
● wp.DumpDatalayers : dumps the list of data layers and their runtime state in the log.
● wp.Runtime.DebugFilerByDatalayer : used to filter which data layer is visible in the
runtime hash 2d debug display.
● wp.Runtime.SetDataLayerRuntimeState [state] [layer] : force a data layer to a
specific runtime state.
● wp.Runtime.ToggleDataLayerActivation [layer] : activate/deactivate a specific runtime
data layer.
● wp.Runtime.ToggleDrawDataLayers : shows list of data layers and their states in the
main view.
HLODs - Hierarchical Level Of Detail (world partition)
Useful links
Official public documentation:
https://docs.unrealengine.com/5.1/en-US/world-partition---hierarchical-level-of-detail-in-unreal-e
ngine/
Subjects to master
Hierarchical setup, World Partition and Grids, Streaming, Instancing, Nanite, Landscape
and Water
Definition
Hierarchical Level Of Detail (HLODs) are a visual representation of a group of actors that is
meant to replace those actors when viewed from a considerable distance. It is often a single
mesh & material, built from the original actors’ geometry, but simplified to reduce memory
usage. Replacing multiple actors by an HLOD will most of the time reduce your draw calls from
N to 1, increasing performance.
World Partition HLODs differ from the traditional UE HLODs in the sense that they aren’t linked
to a level. They are generated from the World Partition grid, without you having to manage actor
clusters.
Important changes in 5.1
● Water HLODs
○ Added support for Water Body actors HLODs.
■ Automatic creation of hlods meshes for water.
■ Settings for material and layer to use within water body actors.
Good practices
● Predefined HLOD layers types, streaming and hierarchy
○ During world conception and pre-production, define the HLODs streaming,
hierarchy and types for the best visual quality at the most optimal cost based on
multiple factors.
■ Factors to consider: platforms memory and performance, instancing,
nanite streaming, world density, world scale, grid sizes, asset types
(trees, buildings, others), etc.
● Seen from runtime/gameplay distance
○ HLODs can be quite ugly when up close if using merged or simplified meshes
types. They are built to be seen from long distances and should always be
evaluated from such distance for quality and performance trade offs.
○ Nanite enabled instanced layers are providing undistinguishable results from the
loaded assets by nanite’s nature and are an extremely powerful approach for
nanite-enabled platforms.
● HLODs layers
○ Worlds can have multiple layers for different types of assets such as Building with
simplified meshes and Vegetation with Instancing, spatially overlapping with their
own cell size and ranges.
○ Use multiple
● Frequent updates
○ HLODs are not important in most workflows BUT they can be extremely
problematic if outdated when doing art composition OR simply playtesting the
game. HLOD generation should occur frequently, this will be further more
important when we will support HLODs in editor.
Pitfalls
● Keeping all actors in HLODs
○ The first goal of using HLODs remains to reduce actor count and improve
performance while maintaining quality over distance. The balance is crucial.
○ Small actors, interiors, undergrounds, and all non-significant assets should not be
added to HLODs.
● Cinematic and Vistas zoomed-in shots
○ Depending on different conditions, having long focal length shots can lead to very
bad visuals by looking at simplified HLODs from up-close.
○ Nanite-enabled instanced layers should help alleviate some of these issues but in
some cases different workarounds must be used such as secondary streaming
sources preloading the background area for the given shot at the expense of
memory and streaming.
○ Other tricks such as larger aperture for tighter depth of field and stronger bokeh
can also be considered when possible.
Limitations
● Generation of large simplified and merged HLODs
○ While generating instanced hlods is quite fast even for worlds such as complex
as The Matrix Awaken demo, generating simplified or merged meshes HLODs
can be extremely time and memory intensive requiring build machines nightly
builds and automation.
● Visibility limited in Editor
○ To preview HLODs in editor, users need to PIE. While in the PIE session, HLODs
actors will also appear within the Scene Outliner from which they can be Pinned
to remain loaded even after closing the PIE session. This is a workaround until
we provide visible HLODs in-editor directly, a high priority element on the
roadmap.
● No custom HLOD support yet
○ The system does not allow specifying custom built HLODs at the moment but it is
on the roadmap.
Current use cases/Scenarios
● The Matrix Awaken demo
○ HLODs setup with 2 layers
■ HLOD0 Nanite-Enabled instanced layer, 256m cells, 768m range,
Spatially Loaded
■ HLOD1 Simplified mesh, 256m cells, always loaded
○ Simplified mesh processing required 10 machines (g4ad.16xlarge instances,
see Amazon EC2 G4 Instances — Amazon Web Services (AWS). Took 5h in
the worst cases.
○ Instanced layer was taking under 10 min to process on a single machine.
● Fortnite Chapter 4
○ HLODs for buildings (2 layers)
■ HLOD0 special Fortnite specific merged mesh with destruction support
(client and server), 256m cells, 512m range, Spatially loaded.
■ HLOD1 simplified mesh, 512m cells, 2048m range, Spatially loaded.
○ HLODs for trees (1 layer)
■ Instanced layer for trees imposters, always loaded.
○ Fortnite handles streaming differently during the drop phase from the bus to
avoid over streaming content before reaching ground level.
○ Loading range can be different for each platform. HLODs content is shared
across all platforms but is displayed at different ranges following the loading
changes and for optimization purposes.
○ Build for HLOD0 and 1 takes around 1h30m.
Roadmap/Future Developments
● HLODs visible in editor
● Custom HLODs support for actors and level instances
Editors and UX
Subjects to master
World Partition, OFPA, Data Layers, HLODs, Loading, Source Control, Unreal
World Partition Editor
The world partition editor is where users can load regions/locations to work in the editor.
New in 5.1:
● Removed editor grid completely and replaced with transient regions and
persistent location actors.
● Shortcuts to load, zoom, play from here, measure, create location volume from
region
○ Shift+Drag will snap selection to the current grid size.
○ Double+Click will move the camera at the clicked location in all viewports.
○ Shift+Double Click will PIE at the clicked location.
○ Control+Double Click will load around the clicked location.
○ Middle Click+Drag will show a measuring tool similar to the top view one.
○ Checking "Follow Player in PIE" will follow the player in the minimap.
● Better UX to indicate that no regions are loaded when loading WP for first time
users.
Actor Editor Context
The Actor Editor Context, new in 5.1, is based on classic level workflow of defining a “Current”
level to work in. In world partition, the actor editor context supports scene outliner folders, data
layers and level instances by simply right clicking and setting Make Current on any of these
supported inputs.
Pin Actor
A pin column is enabled by default in the scene outliner within World Partition levels. This allows
users to selectively load actors to keep them available while not loaded through the World
Partition Editor.
Actors can be automatically pinned by their unsaved state after unloading a region or being
created outside of a loaded area.
Pinning behaves and is impacted by the same rules as regular loading, this means that at least
one data layer assigned to an actor needs to be loaded for the actor pinning to load the actor.
Bookmarks and Locations
Bookmarks are our next step to help navigate in large open worlds with World Partition. As a
first step toward this google-map like design, is the Location volumes introduced in 5.1.
Locations are 3D regions, currently limited top box shapes, to identify different areas in the
world.
HLODs Generation
HLOD generation can be triggered from the editor menu, this will launch a separate process
using the commandlet builder to rebuild all HLODs for a specified layer(s) for the loaded world in
the editor.
World Partition Editor Minimap Generation
Same as with the HLODs generation, the world partition editor mini-map can be started from the
editor.
Commandlet
WorldPartition Builder
There is a WorldPartition Builder framework that licensees can extend to do build offline or in editor
processes for WP worlds. This includes facilities to iteratively load the whole world through regions
and manage actor memory through garbage collection.
Conversion to WP:
https://docs.unrealengine.com/5.1/en-US/world-partition-in-unreal-engine/#convertingexistinglev
elstouseworldpartition
HLOD:
https://docs.unrealengine.com/5.1/en-US/world-partition---hierarchical-level-of-detail-in-unreal-e
ngine/#usinghlodlayers
Roadmap/Future Developments
● Unsaved list in view changelist window.
● Bookmark system.
● Filters for Unsaved, Uncontrolled and Locked in Scene Outliner (5.2 - done)
● Bug-it-Go creation shortcut in the world map editor to easily share locations to look at
between users (5.2 - done).
Data streaming outside of World Partition
Subjects to master
World Partition, HLODs, Streaming, Nanite, Texture, Platforms and Scalability, Unreal
Nanite streaming
Official Nanite Doc:
https://docs.unrealengine.com/5.1/en-US/nanite-virtualized-geometry-in-unreal-engine/
Texture streaming
Official Texture Streaming Doc:
https://docs.unrealengine.com/5.1/en-US/texture-streaming-in-unreal-engine/
Production Pipeline and Workflow
Approved for Production version
It is strongly recommended to consider having a QA tested stable production version released
every day on large production. This should be done to prevent halting the production with major
editor breaking issues introduced with new features and code. Stability is key in order to keep
momentum and avoid frustration.
Mandatory versions could also be required in some cases where file version has been bumped
or for changes that impact content and functionality/gameplay/stability due to incompatibility with
new code.
Budgeting
Budgeting should occur at every stage of production with projection at the beginning,
re-evaluated with design changes and actual content being produced.
Budgeting should be done for memory, performance and disk size. All platforms should be
considered with scalability in mind. Using different features such as Nanite and Texture
streamers will greatly reduce the stress of having very tight budgeting constraints but requires
full understanding, disk space evaluation and fallbacks for platforms without these features
(depending on the project targets).
Validation
Check map for Errors is a great way to find content errors that will break the content, gameplay,
cooking, etc This should be monitored by every content creator.
Submit Validation has been added to the Source Control - View Changelist submit process. This
will validate upon submit (or on request) content found within a specific changelist. The Submit
Validation can be extended in code by projects for any specific needs. Basic validation comes
standard in UE, such as referencing files outside of CL, unsaved content, etc.