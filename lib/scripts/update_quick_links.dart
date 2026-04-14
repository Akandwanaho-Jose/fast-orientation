import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/core/services/quick_links_service.dart';

class UpdateQuickLinksScript {
  static Future<void> syncDefaults() async {
    final firestore = FirebaseFirestore.instance;

    for (final link in QuickLinksService.defaultLinks) {
      await firestore.collection(QuickLinksService.collectionName).doc(link.id).set({
        'title': link.title,
        'subtitle': link.subtitle,
        'url': link.url,
        'order': link.order,
        'enabled': link.enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
