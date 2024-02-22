import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:collection/collection.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item.dart';
import 'package:fluffychat/pages/chat_list/search_title.dart';
import 'package:fluffychat/pages/chat_list/study_view.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:matrix/matrix.dart' as sdk;
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/localized_exception_extension.dart';
import '../../widgets/matrix.dart';
import 'chat_list_header.dart';

List<String> roomIdForScrappedCourses = [];
List<String> roomNamesForScrappedCourses = [];

class SpaceView extends StatefulWidget {
  final ChatListController controller;
  final ScrollController scrollController;

  const SpaceView(
    this.controller, {
    super.key,
    required this.scrollController,
  });

  @override
  State<SpaceView> createState() => _SpaceViewState();
}

class _SpaceViewState extends State<SpaceView> {
  static final Map<String, Future<GetSpaceHierarchyResponse>> _requests = {};

  String? prevBatch;
  bool publicGroup = false;
  bool isLoading = false;

  String? tempRole = "";
  bool isTeacher = false;

  void getUserEmail() async {
    tempRole = await getRoleFromPreferences();
    final client = Matrix.of(context).client;
    final String email = client.userID!.localpart!;
    String? savedEmail = await getEmailFromPreferences();
    if (savedEmail!.isEmpty) {
      await saveEmailToPreferences(email);
      final role = await showRoleSelectionDialog(context);
      await saveRoleToPreferences(role!);
      savedEmail = await getEmailFromPreferences();
    } else if (savedEmail.isNotEmpty && savedEmail != email) {
      await saveEmailToPreferences(email);
      final role = await showRoleSelectionDialog(context);
      await saveRoleToPreferences(role!);
      savedEmail = await getEmailFromPreferences();
    } else if (savedEmail.isNotEmpty && savedEmail == email) {}
    isTeacher = isTeacherEmail(savedEmail!);
    setState(() {});
  }

  // Method to save email to shared preferences
  Future<void> saveEmailToPreferences(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tempEmail', email);
  }

// Method to retrieve email from shared preferences
  Future<String?> getEmailFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('tempEmail') ?? "";
  }

  // Method to save role to shared preferences
  Future<void> saveRoleToPreferences(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tempRole', role);
  }

// Method to retrieve role from shared preferences
  Future<String?> getRoleFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('tempRole') ?? "";
  }

  Future<String?> showRoleSelectionDialog(BuildContext context) async {
    String? selectedRole;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select your role'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile(
                  title: const Text('Teacher'),
                  value: 'Teacher',
                  groupValue: selectedRole,
                  onChanged: (value) {
                    setState(() => selectedRole = value);
                    Navigator.of(context).pop();
                  },
                ),
                RadioListTile(
                  title: const Text('Research assistant'),
                  value: 'Research assistant',
                  groupValue: selectedRole,
                  onChanged: (value) {
                    setState(() => selectedRole = value);
                    Navigator.of(context).pop();
                  },
                ),
                RadioListTile(
                  title: const Text('Others'),
                  value: 'Others',
                  groupValue: selectedRole,
                  onChanged: (value) {
                    setState(() => selectedRole = value);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    return selectedRole;
  }

  bool isStudentEmail(String email) {
    // Regular expression to match both formats for student emails
    final RegExp studentEmailRegex =
        RegExp(r'^[^@=]+(@|=40)stud\.hs-heilbronn\.de$');
    return studentEmailRegex.hasMatch(email);
  }

  bool isTeacherEmail(String email) {
    // Regular expression to match both formats for teacher emails
    final RegExp teacherEmailRegex = RegExp(r'^[^@=]+(@|=40)hs-heilbronn\.de$');
    return teacherEmailRegex.hasMatch(email);
  }

  @override
  void initState() {
    super.initState();
    getUserEmail();
  }

  // Function to hit new spcae Api Ffor scrapped cources from the web
  Future<void> submitAction(String data) async {
    final matrix = Matrix.of(context);
    final allSpaces = matrix.client.rooms.where((room) => room.isSpace);
    bool isSpaceNameTaken = false;
    isSpaceNameTaken = allSpaces.any((element) => element.name == data);
    if (isSpaceNameTaken) {
      return;
    } else {
      final spaceId = await matrix.client.createRoom(
        preset: publicGroup
            ? sdk.CreateRoomPreset.publicChat
            : sdk.CreateRoomPreset.privateChat,
        creationContent: {'type': RoomCreationTypes.mSpace},
        visibility: publicGroup ? sdk.Visibility.public : null,
        roomAliasName: publicGroup && data.isNotEmpty
            ? data.trim().toLowerCase().replaceAll(' ', '_')
            : null,
        name: data.isNotEmpty ? data : null,
      );
      roomIdForScrappedCourses.add(spaceId);
      roomNamesForScrappedCourses.add("$data+$spaceId");
    }
  }

  // Function to create new chat for scrapped cources from the web
  Future<void> submitActionToCreateGroups(
    String groupName,
    Room? space,
  ) async {
    final client = Matrix.of(context).client;
    final String roomId = await client.createGroupChat(
      visibility: sdk.Visibility.private,
      preset: sdk.CreateRoomPreset.privateChat,
      groupName: groupName.isNotEmpty ? groupName : null,
    );
    space!.setSpaceChild(roomId);
  }

  void _refresh() {
    setState(() {
      _requests.remove(widget.controller.activeSpaceId);
    });
  }

  Future<GetSpaceHierarchyResponse> getFuture(String activeSpaceId) =>
      _requests[activeSpaceId] ??= Matrix.of(context).client.getSpaceHierarchy(
            activeSpaceId,
            maxDepth: 1,
            from: prevBatch,
          );

  void _onJoinSpaceChild(SpaceRoomsChunk spaceChild) async {
    final client = Matrix.of(context).client;
    final space = client.getRoomById(widget.controller.activeSpaceId!);
    if (client.getRoomById(spaceChild.roomId) == null) {
      final result = await showFutureLoadingDialog(
        context: context,
        future: () async {
          await client.joinRoom(
            spaceChild.roomId,
            serverName: space?.spaceChildren
                .firstWhereOrNull(
                  (child) => child.roomId == spaceChild.roomId,
                )
                ?.via,
          );
          if (client.getRoomById(spaceChild.roomId) == null) {
            await client.waitForRoomInSync(spaceChild.roomId, join: true);
          }
        },
      );
      if (result.error != null) return;
      _refresh();
    }
    if (spaceChild.roomType == 'm.space') {
      if (spaceChild.roomId == widget.controller.activeSpaceId) {
        context.go('/rooms/${spaceChild.roomId}');
      } else {
        widget.controller.setActiveSpace(spaceChild.roomId);
      }
      return;
    }
    context.go('/rooms/${spaceChild.roomId}');
  }

  void _onSpaceChildContextMenu([
    SpaceRoomsChunk? spaceChild,
    Room? room,
  ]) async {
    final client = Matrix.of(context).client;
    final activeSpaceId = widget.controller.activeSpaceId;
    final activeSpace =
        activeSpaceId == null ? null : client.getRoomById(activeSpaceId);
    final action = await showModalActionSheet<SpaceChildContextAction>(
      context: context,
      title: spaceChild?.name ??
          room?.getLocalizedDisplayname(
            MatrixLocals(L10n.of(context)!),
          ),
      message: spaceChild?.topic ?? room?.topic,
      actions: [
        if (room == null)
          SheetAction(
            key: SpaceChildContextAction.join,
            label: L10n.of(context)!.joinRoom,
            icon: Icons.send_outlined,
          ),
        if (spaceChild != null && (activeSpace?.canSendDefaultStates ?? false))
          SheetAction(
            key: SpaceChildContextAction.removeFromSpace,
            label: L10n.of(context)!.removeFromSpace,
            icon: Icons.delete_sweep_outlined,
          ),
        if (room != null)
          SheetAction(
            key: SpaceChildContextAction.leave,
            label: L10n.of(context)!.leave,
            icon: Icons.delete_outlined,
            isDestructiveAction: true,
          ),
      ],
    );
    if (action == null) return;

    switch (action) {
      case SpaceChildContextAction.join:
        _onJoinSpaceChild(spaceChild!);
        break;
      case SpaceChildContextAction.leave:
        await showFutureLoadingDialog(
          context: context,
          future: room!.leave,
        );
        break;
      case SpaceChildContextAction.removeFromSpace:
        await showFutureLoadingDialog(
          context: context,
          future: () => activeSpace!.removeSpaceChild(spaceChild!.roomId),
        );
        break;
    }
  }

  void showCustomSnackbarLong(BuildContext context, String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 10,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
      webBgColor: "#000000",
      webShowClose: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    final activeSpaceId = widget.controller.activeSpaceId;
    final allSpaces = client.rooms.where((room) => room.isSpace);
    if (activeSpaceId == null) {
      final rootSpaces = allSpaces
          .where(
            (space) => !allSpaces.any(
              (parentSpace) => parentSpace.spaceChildren
                  .any((child) => child.roomId == space.id),
            ),
          )
          .toList();

      return Stack(
        children: [
          CustomScrollView(
            controller: widget.scrollController,
            slivers: [
              ChatListHeader(controller: widget.controller),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final rootSpace = rootSpaces[i];
                    final displayname = rootSpace.getLocalizedDisplayname(
                      MatrixLocals(L10n.of(context)!),
                    );
                    return Material(
                      color: Theme.of(context).colorScheme.background,
                      child: Column(
                        children: [
                          ListTile(
                            leading: Avatar(
                              mxContent: rootSpace.avatar,
                              name: displayname,
                            ),
                            title: Text(
                              displayname,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              L10n.of(context)!.numChats(
                                rootSpace.spaceChildren.length.toString(),
                              ),
                            ),
                            onTap: () =>
                                widget.controller.setActiveSpace(rootSpace.id),
                            onLongPress: () =>
                                _onSpaceChildContextMenu(null, rootSpace),
                            trailing: const Icon(Icons.chevron_right_outlined),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: rootSpaces.length,
                ),
              ),
            ],
          ),
          //Button To open space view syncronize course
          if ((tempRole == "Teacher" || tempRole == "Research assistant") &&
              isTeacher)
            Positioned(
              top: 25,
              right: 15,
              child: FloatingActionButton(
                child: const Icon(Icons.replay),
                onPressed: () {
                  Navigator.of(context)
                      .push(
                    MaterialPageRoute(
                      builder: (context) => const StudyViewSpace(),
                    ),
                  )
                      //This then method will be called when we poped from the above pushed Page(StudyViewSpace);
                      .then((value) async {
                    if (value != null) {
                      // Start the loading
                      setState(() {
                        isLoading = true;
                      });

                      for (final data in coursesData) {
                        // Call api function to create new space after the wait of 3 seconds
                        final name = "${data["name"]}_${data['refId']!}";
                        await submitAction(name);
                        await Future.delayed(
                          const Duration(seconds: 3),
                        );
                      }
                      // Stop the loading and empty the global list
                      setState(() {
                        isLoading = false;
                        coursesData = [];
                      });
                    }
                  });
                },
              ),
            ),
          // Loading indicator while hitting api for cources
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: SizedBox(
                  height: 50,
                  child: Lottie.asset(
                    "assets/loading.json",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
        ],
      );
    }
    return FutureBuilder<GetSpaceHierarchyResponse>(
      future: getFuture(activeSpaceId),
      builder: (context, snapshot) {
        // Check the current active space id if it present in our global list
        final gotId = roomIdForScrappedCourses.any(
          (element) => element == activeSpaceId,
        );

        final gotName = roomNamesForScrappedCourses
            .any((element) => element.split("+").last == activeSpaceId);
        // if we go that id we will get that room id the pass that id to create chat within that space
        if (gotId && gotName) {
          final space = Matrix.of(context).client.getRoomById(activeSpaceId);
          final name = roomNamesForScrappedCourses.firstWhere(
            (element) => element.split("+").last == activeSpaceId,
            orElse: () =>
                "", // Provide a default value or handle the case when no match is found
          );
          submitActionToCreateGroups(
            "${name.split("+").first}(With Teacher)",
            space,
          );
          roomIdForScrappedCourses
              .removeWhere((element) => element == activeSpaceId);
          roomNamesForScrappedCourses.removeWhere(
            (element) => element.split("+").last == activeSpaceId,
          );
          showCustomSnackbarLong(context, "Please wait");
          Future.delayed(const Duration(seconds: 3), () => _refresh());
        }
        final response = snapshot.data;
        final error = snapshot.error;
        if (error != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(error.toLocalizedString(context)),
              ),
              IconButton(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_outlined),
              ),
            ],
          );
        }
        if (response == null) {
          return CustomScrollView(
            slivers: [
              ChatListHeader(controller: widget.controller),
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
              ),
            ],
          );
        }
        final parentSpace = allSpaces.firstWhereOrNull(
          (space) =>
              space.spaceChildren.any((child) => child.roomId == activeSpaceId),
        );
        final spaceChildren = response.rooms;
        final canLoadMore = response.nextBatch != null;
        return WillPopScope(
          onWillPop: () async {
            if (parentSpace != null) {
              widget.controller.setActiveSpace(parentSpace.id);
              return false;
            }
            return true;
          },
          child: CustomScrollView(
            controller: widget.scrollController,
            slivers: [
              ChatListHeader(controller: widget.controller),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    if (i == 0) {
                      return ListTile(
                        leading: BackButton(
                          onPressed: () =>
                              widget.controller.setActiveSpace(parentSpace?.id),
                        ),
                        title: Text(
                          parentSpace == null
                              ? L10n.of(context)!.allSpaces
                              : parentSpace.getLocalizedDisplayname(
                                  MatrixLocals(L10n.of(context)!),
                                ),
                        ),
                        trailing: IconButton(
                          icon: snapshot.connectionState != ConnectionState.done
                              ? const CircularProgressIndicator.adaptive()
                              : const Icon(Icons.refresh_outlined),
                          onPressed:
                              snapshot.connectionState != ConnectionState.done
                                  ? null
                                  : _refresh,
                        ),
                      );
                    }
                    i--;
                    if (canLoadMore && i == spaceChildren.length) {
                      return ListTile(
                        title: Text(L10n.of(context)!.loadMore),
                        trailing: const Icon(Icons.chevron_right_outlined),
                        onTap: () {
                          prevBatch = response.nextBatch;
                          _refresh();
                        },
                      );
                    }
                    final spaceChild = spaceChildren[i];
                    final room = client.getRoomById(spaceChild.roomId);
                    if (room != null && !room.isSpace) {
                      return ChatListItem(
                        room,
                        onLongPress: () =>
                            _onSpaceChildContextMenu(spaceChild, room),
                        activeChat: widget.controller.activeChat == room.id,
                      );
                    }
                    final isSpace = spaceChild.roomType == 'm.space';
                    final topic = spaceChild.topic?.isEmpty ?? true
                        ? null
                        : spaceChild.topic;
                    if (spaceChild.roomId == activeSpaceId) {
                      return SearchTitle(
                        title: spaceChild.name ??
                            spaceChild.canonicalAlias ??
                            'Space',
                        icon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Avatar(
                            size: 24,
                            mxContent: spaceChild.avatarUrl,
                            name: spaceChild.name,
                            fontSize: 9,
                          ),
                        ),
                        color: Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .withAlpha(128),
                        trailing: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Icon(Icons.edit_outlined),
                        ),
                        onTap: () => _onJoinSpaceChild(spaceChild),
                      );
                    }
                    return ListTile(
                      leading: Avatar(
                        mxContent: spaceChild.avatarUrl,
                        name: spaceChild.name,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              spaceChild.name ??
                                  spaceChild.canonicalAlias ??
                                  L10n.of(context)!.chat,
                              maxLines: 1,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!isSpace) ...[
                            const Icon(
                              Icons.people_outline,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              spaceChild.numJoinedMembers.toString(),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                      onTap: () => _onJoinSpaceChild(spaceChild),
                      onLongPress: () =>
                          _onSpaceChildContextMenu(spaceChild, room),
                      subtitle: Text(
                        topic ??
                            (isSpace
                                ? L10n.of(context)!.enterSpace
                                : L10n.of(context)!.enterRoom),
                        maxLines: 1,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      trailing: isSpace
                          ? const Icon(Icons.chevron_right_outlined)
                          : null,
                    );
                  },
                  childCount: spaceChildren.length + 1 + (canLoadMore ? 1 : 0),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum SpaceChildContextAction {
  join,
  leave,
  removeFromSpace,
}
