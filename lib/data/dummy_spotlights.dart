import '../models/spotlight_item.dart';

final List<SpotlightItem> dummySpotlights = [
  SpotlightItem(
    id: 'spotlight_01',
    imagePath: 'assets/images/spotlight_owarai.png',
    isVisible: true,
    actionType: SpotlightActionType.event,
    actionValue: 'event_001',
  ),
  SpotlightItem(
    id: 'spotlight_02',
    imagePath: 'assets/images/spotlight_valorant.png',
    isVisible: true,
    actionType: SpotlightActionType.event,
    actionValue: 'event_011',
  ),
  SpotlightItem(
    id: 'spotlight_03',
    imagePath: 'assets/images/spotlight_external.png',
    isVisible: true,
    actionType: SpotlightActionType.url,
    actionValue: 'https://www.tcu.ac.jp/',
  ),
  SpotlightItem(
    id: 'spotlight_04',
    imagePath: 'assets/images/spotlight_secret.png',
    isVisible: false,//falseなのでこれは表示されない
    actionType: SpotlightActionType.event,
    actionValue: 'event_999',
  ),
];