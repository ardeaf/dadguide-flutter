import 'package:dadguide2/components/enums.dart';
import 'package:dadguide2/components/images.dart';
import 'package:dadguide2/components/navigation.dart';
import 'package:dadguide2/components/notifications/tracking.dart';
import 'package:dadguide2/components/settings_manager.dart';
import 'package:dadguide2/data/data_objects.dart';
import 'package:dadguide2/l10n/localizations.dart';
import 'package:dadguide2/screens/event/event_search_bloc.dart';
import 'package:dadguide2/theme/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Parent class for items which can show up in the event list, since they're different types.
abstract class ListItem {}

/// A ListItem that contains data to display a heading.
class HeadingItem implements ListItem {
  final ScheduleSubSection section;

  HeadingItem(this.section);
}

/// A ListItem that contains data to display an event row.
class EventRowItem implements ListItem {
  final ListEvent model;

  EventRowItem(this.model);
}

List<ListItem> rowsToListItems(List<ListEvent> events, ScheduleTabKey tabKey) {
  var results = <ListItem>[];

  var special = events.where((e) => e.event.groupName == null && e.dungeon != null).toList();
  var starter = events.where((e) => e.event.groupName != null && e.dungeon != null).toList();

  special.sort(_compareEvents);
  starter.sort(_compareEvents);

  // Filtering on tab key might be unnecessary here.
  if (tabKey == ScheduleTabKey.all || tabKey == ScheduleTabKey.guerrilla) {
    if (starter.isNotEmpty) {
      results.add(HeadingItem(ScheduleSubSection.starter_dragons));
      results.addAll(starter.map((l) => EventRowItem(l)));
    }
  }

  if (tabKey == ScheduleTabKey.all || tabKey == ScheduleTabKey.special) {
    if (special.isNotEmpty) {
      results.add(HeadingItem(ScheduleSubSection.special));
      results.addAll(special.map((l) => EventRowItem(l)));
    }
  }

  return results;
}

int _compareEvents(ListEvent l, ListEvent r) {
  var group = (r.event.groupName ?? '').compareTo(l.event.groupName ?? '');
  var open = group != 0 ? group : l.event.startTimestamp.compareTo(r.event.startTimestamp);
  var close = open != 0 ? open : l.event.endTimestamp.compareTo(r.event.endTimestamp);
  var dungeon = close != 0 ? close : l.dungeon.dungeonId.compareTo(r.dungeon.dungeonId);
  var info = dungeon != 0 ? dungeon : (l.event.infoNa ?? '').compareTo(r.event.infoNa ?? '');
  return info;
}

/// Converts a stream of lists of Events into a ListView of data.
///
/// This is a stream because the user's actions (e.g. changing the date) may require a new data
/// publication, updating the UI.
class EventListContents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var loc = DadGuideLocalizations.of(context);
    var displayState = Provider.of<ScheduleTabState>(context);
    return StreamBuilder<List<ListEvent>>(
        stream: displayState.searchBloc.searchResults,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            Fimber.e('Error loading data', ex: snapshot.error);
            return Center(child: Icon(Icons.error));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: CircularProgressIndicator());
          }

          var data = snapshot.data;
          var listItems = rowsToListItems(data, displayState.tab);
          if (listItems.isEmpty) {
            return Center(child: Text(loc.noData));
          }

          return ListView.separated(
            itemCount: listItems.length,
            separatorBuilder: (context, index) =>
                listItems[index] is EventRowItem ? Divider(height: 0) : Container(),
            itemBuilder: (context, index) {
              var item = listItems[index];
              if (item is HeadingItem) {
                return Container(
                  color: grey(context, 300),
                  child: Center(
                      child: Padding(padding: EdgeInsets.all(4.0), child: Text(item.section.name))),
                );
              } else if (item is EventRowItem) {
                return EventListRow(item.model);
              } else {
                throw 'Unexpected item type';
              }
            },
          );
        });
  }
}

/// An individual event row.
class EventListRow extends StatelessWidget {
  final ListEvent model;
  const EventListRow(this.model, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TrackingNotifier>(create: (context) => TrackingNotifier()),
        Consumer<TrackingNotifier>(
          builder: (context, trackedNotifier, __) => InkWell(
            onLongPress: () async {
              var isTracked = Prefs.trackedDungeons.contains(model.dungeon.dungeonId);
              await showDungeonMenu(context, model.dungeon.dungeonId, isTracked);
              trackedNotifier.trackingChanged();
            },
            onTap: goToDungeonFn(context, model.dungeon?.dungeonId),
            child: EventListRowContents(model, key: ValueKey(model.event.eventId)),
          ),
        ),
      ],
    );
  }
}

class EventListRowContents extends StatelessWidget {
  static final DateFormat longFormat = DateFormat.MMMd().add_jm();
  static final DateFormat shortFormat = DateFormat.jm();

  final ListEvent model;

  const EventListRowContents(this.model, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var loc = DadGuideLocalizations.of(context);
    var isTracked = Prefs.trackedDungeons.contains(model.dungeon.dungeonId);

    return Container(
        padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          children: [
            PadIcon(model.iconId, size: 36),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isTracked) TrackedChip(),
                  FittedBox(alignment: Alignment.centerLeft, child: Text(headerText())),
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.caption,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (model.isClosed()) Icon(Icons.close, color: Colors.red, size: 12),
                        if (model.isOpen()) Icon(Icons.check, color: Colors.green, size: 12),
                        if (model.isPending())
                          Icon(
                            FontAwesome.calendar_check_o,
                            color: Colors.orange,
                            size: 12,
                          ),
                        SizedBox(width: 4),
                        Text(underlineText(loc, DateTime.now())),
                        SizedBox(width: 4),
                        if (!model.isClosed()) Text(stamRcvText()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }

  String headerText() {
    String text = model.dungeonName() ?? model.eventInfo();
    if (model.event.groupName != null) {
      text = '[${model.event.groupName}] $text';
    }
    return text ?? 'error';
  }

  String stamRcvText() {
    var timeTo = model.isOpen() ? model.endTime : model.startTime;
    var stamRcv = timeTo.difference(DateTime.now()).inMinutes ~/ 3;
    var stamRcvStr = NumberFormat.decimalPattern().format(stamRcv);
    return '[Stam.Recovered $stamRcvStr]';
  }

  String underlineText(DadGuideLocalizations loc, DateTime displayedDate) {
    if (model.isClosed()) {
      return loc.eventClosed;
    }

    String text = '';
    if (!model.isOpen()) {
      text = _adjDate(displayedDate, model.startTime);
    }
    text += ' ~ ';
    text += _adjDate(displayedDate, model.endTime);

    int deltaDays = model.daysUntilClose();
    if (deltaDays > 0) {
      var dayText = loc.eventDays(deltaDays);
      text += ' [$dayText]';
    }
    return text.trim();
  }

  String _adjDate(DateTime displayedDate, DateTime timeToDisplay) {
    displayedDate = displayedDate.toLocal();
    timeToDisplay = timeToDisplay.toLocal();
    if (displayedDate.day != timeToDisplay.day) {
      return longFormat.format(timeToDisplay);
    } else {
      return shortFormat.format(timeToDisplay);
    }
  }
}
