import 'package:async/async.dart';
import 'package:dadguide2/components/images.dart';
import 'package:dadguide2/components/navigation.dart';
import 'package:dadguide2/data/database.dart';
import 'package:dadguide2/data/tables.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MonsterTab extends StatefulWidget {
  MonsterTab({Key key}) : super(key: key);

  @override
  _MonsterTabState createState() => _MonsterTabState();
}

class _MonsterTabState extends State<MonsterTab> {
  final _memoizer = AsyncMemoizer<List<FullMonster>>();

  @override
  Widget build(BuildContext context) {
    print('adding a monstertab');
    return ChangeNotifierProvider(
      builder: (context) => MonsterDisplayState(),
      child: Column(children: <Widget>[
        MonsterSearchBar(),
        Expanded(child: _searchResults()),
        MonsterDisplayOptionsBar(),
      ]),
    );
  }

  FutureBuilder<List<FullMonster>> _searchResults() {
    var dataFuture = _memoizer.runOnce(() async {
      var database = await DatabaseHelper.instance.database;
      return database.allMonstersWithAwakenings;
    }).catchError((ex) {
      print(ex);
    });

    return FutureBuilder<List<FullMonster>>(
        future: dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            print('no data!');
            return Center(child: CircularProgressIndicator());
          }

          print('got data! ${snapshot.data.length}');

          return ListView(
              children: snapshot.data.map((monster) {
            return MonsterListRow(monster);
          }).toList());
        });
  }
}

class MonsterSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MonsterDisplayState>(context);
    return Container(
      color: Colors.blue,
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        children: <Widget>[
          Icon(Icons.clear_all),
          Expanded(child: TextField()),
          Icon(Icons.cancel),
        ],
      ),
    );
  }
}

class MonsterDisplayOptionsBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MonsterDisplayState>(context);
    return Material(
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.star_border),
            color: controller.favoritesOnly ? Colors.amber : Colors.black,
            onPressed: () => controller.favoritesOnly = !controller.favoritesOnly,
          ),
          IconButton(
            icon: Icon(Icons.new_releases),
            color: controller.sortNew ? Colors.amber : Colors.black,
            onPressed: () => controller.sortNew = !controller.sortNew,
          ),
          IconButton(
            icon: Icon(Icons.portrait),
            color: controller.pictureMode ? Colors.amber : Colors.black,
            onPressed: () => controller.pictureMode = !controller.pictureMode,
          ),
          IconButton(
            icon: Icon(Icons.sort),
            color: controller.useCustomSort ? Colors.amber : Colors.black,
            onPressed: () => controller.useCustomSort = !controller.useCustomSort,
          ),
          IconButton(
            icon: Icon(Icons.stars),
            color: controller.showAwakenings ? Colors.amber : Colors.black,
            onPressed: () => controller.showAwakenings = !controller.showAwakenings,
          ),
          IconButton(
            icon: Icon(Icons.change_history),
            onPressed: () => {},
          ),
        ],
      ),
    );
  }
}

class MonsterSort {}

class MonsterDisplayState with ChangeNotifier {
  bool _favoritesOnly = false;
  bool _sortNew = false;
  bool _pictureMode = false;
  bool _useCustomSort = false;
  MonsterSort _customSort = MonsterSort();
  bool _showAwakenings = false;

  bool get favoritesOnly => _favoritesOnly;
  bool get sortNew => _sortNew;
  bool get pictureMode => _pictureMode;
  bool get useCustomSort => _useCustomSort;
  MonsterSort get customSort => _customSort;
  bool get showAwakenings => _showAwakenings;

  set showAwakenings(bool value) {
    _showAwakenings = value;
    notifyListeners();
  }

  set customSort(MonsterSort value) {
    _customSort = value;
    notifyListeners();
  }

  set useCustomSort(bool value) {
    _useCustomSort = value;
    notifyListeners();
  }

  set pictureMode(bool value) {
    _pictureMode = value;
    notifyListeners();
  }

  set sortNew(bool value) {
    _sortNew = value;
    notifyListeners();
  }

  set favoritesOnly(bool value) {
    _favoritesOnly = value;
    notifyListeners();
  }
}

class MonsterListRow extends StatelessWidget {
  final FullMonster _model;
  const MonsterListRow(this._model, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var m = _model.monster;
    return InkWell(
      onTap: goToMonsterFn(context, m.monsterId),
      child: Container(
          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Row(
            children: <Widget>[
              PadIcon(m.monsterId),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                        style: Theme.of(context).textTheme.caption,
                        child: Row(children: [
                          Text('No. ${m.monsterNoJp}'),
                          Spacer(),
                          Text('MP ? / * ${m.cost} / S? -> ?'),
                        ])),
                    Text(m.nameNa),
                    DefaultTextStyle(
                      style: Theme.of(context).textTheme.caption,
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Lv. ${m.level}'),
                        Text('HP ${m.hpMax}'),
                        Text('ATK ${m.atkMax}'),
                        Text('RCV ${m.rcvMax}'),
                        Text('WT ??'),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }
}