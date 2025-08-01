enum SpotlightActionType {
  event,
  url,
}

class SpotlightItem {
  final String id;
  final String imagePath;
  final bool isVisible;
  final SpotlightActionType actionType;
  final String actionValue;

  const SpotlightItem({
    required this.id,
    required this.imagePath,
    this.isVisible = true,
    required this.actionType,
    required this.actionValue,
  });
}