import '../models/info_link_item.dart';

// サーバーから取得するデータを模したもの
final List<InfoLinkItem> dummyInfoLinks = [
  InfoLinkItem(
    title: '横浜祭公式サイト',
    url: 'https://yokohama-fest.net/29th',
    iconName: 'public',
  ),
  InfoLinkItem(
    title: 'お問い合わせ',
    url: 'https://yokohama-fest.net/29th/form',
    iconName: 'feedback_outlined',
  ),
  InfoLinkItem(
    title: 'プライバシーポリシー',
    url: 'https://yokohama-fest.net/29th', //プライバシーポリシーができていないので、ホームページを仮置き
    iconName: 'privacy_tip_outlined',
  ),
];