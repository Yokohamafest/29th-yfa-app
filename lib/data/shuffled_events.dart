import '../data/dummy_events.dart';
import '../models/event_item.dart';

final List<EventItem> shuffledDummyEvents = dummyEvents
    .where((event) => !event.hideFromList)
    .toList()
  ..shuffle();