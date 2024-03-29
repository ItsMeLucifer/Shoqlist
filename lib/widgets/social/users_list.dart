import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/models/user.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';

import '../../main.dart';

class UsersList extends ConsumerWidget {
  final Function _acceptAction;
  final List<User> _usersList;
  final String? _dialogTitle;
  final Function? _declineAction;
  final double _elementWidth;

  UsersList(
    this._acceptAction,
    this._usersList, [
    this._dialogTitle,
    this._declineAction,
    this._elementWidth = 0.7,
  ]);

  Widget build(BuildContext context, WidgetRef ref) {
    final friendsServiceVM = ref.watch(friendsServiceProvider);
    final screenSize = MediaQuery.of(context).size;
    final arrowIcon = Icon(
      Icons.arrow_forward_ios,
      color: Theme.of(context).listTileTheme.iconColor,
      size: 20,
    );
    return ListView.builder(
        shrinkWrap: false,
        itemCount: _usersList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(top: 2.0, left: 10, right: 10),
            child: GestureDetector(
              onTap: () {
                friendsServiceVM.currentUserIndex = index;
                if (_dialogTitle == null) {
                  return _acceptAction(context);
                }
                showDialog(
                  context: context,
                  builder: (context) {
                    return YesNoDialog(
                      _acceptAction,
                      _dialogTitle!,
                      _declineAction,
                    );
                  },
                );
              },
              child: Card(
                color: Theme.of(context).listTileTheme.tileColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: 60,
                  ),
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Theme.of(context).listTileTheme.iconColor,
                        size: 40,
                      ),
                      SizedBox(width: screenSize.width * 0.05 * _elementWidth),
                      Column(
                        children: [
                          Container(
                            width: screenSize.width * _elementWidth -
                                arrowIcon.size! / 5,
                            child: Text(
                              _usersList[index].nickname,
                              overflow: TextOverflow.fade,
                              maxLines: 1,
                              softWrap: false,
                              style:
                                  Theme.of(context).primaryTextTheme.titleLarge,
                            ),
                          ),
                          Container(
                            width: screenSize.width * _elementWidth -
                                arrowIcon.size! / 5,
                            child: Text(
                              _usersList[index].email,
                              overflow: TextOverflow.fade,
                              maxLines: 1,
                              softWrap: false,
                              style:
                                  Theme.of(context).primaryTextTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      arrowIcon,
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }
}
