import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/features/annoucements/models/announcement.dart';
import 'package:fast/core/services/lib/core/services/CloudinaryService.dart'; // Import your CloudinaryService
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  /// Create announcement with multiple images and enhanced error handling
  Future<void> createAnnouncement({
    required String title,
    required String description,
    required String? category,
    required List<XFile>? imageFiles,
    String priority = 'normal',
    bool isPinned = false,
    List<String> tags = const [],
  }) async {
    try {
      // Validate input
      if (title.trim().isEmpty) {
        throw ArgumentError('Title cannot be empty');
      }
      if (description.trim().isEmpty) {
        throw ArgumentError('Description cannot be empty');
      }

      List<String> imageUrls = [];
      
      // Upload multiple images if provided
      if (imageFiles != null && imageFiles.isNotEmpty) {
        final maxImages = 5; // Limit to 5 images per announcement
        final imagesToUpload = imageFiles.take(maxImages).toList();
        
        if (kDebugMode) {
          print('Uploading ${imagesToUpload.length} images to Cloudinary...');
        }
        
        for (int i = 0; i < imagesToUpload.length; i++) {
          final file = imagesToUpload[i];
          
          // Validate file size (limit to 5MB)
          final fileSize = await File(file.path).length();
          if (fileSize > 5 * 1024 * 1024) {
            throw Exception('Image ${i + 1} is too large. Maximum size is 5MB.');
          }
          
          try {
            final imageUrl = await _cloudinaryService.uploadImage(file);
            imageUrls.add(imageUrl);
            if (kDebugMode) {
              print('Successfully uploaded image ${i + 1}');
            }
          } catch (e) {
            if (kDebugMode) {
              print('Failed to upload image ${i + 1}: $e');
            }
            // Continue with other images instead of failing completely
          }
        }
        
        if (kDebugMode) {
          print('Successfully uploaded ${imageUrls.length} images to Cloudinary');
        }
      }

      // Create announcement with enhanced data structure
      final announcementData = {
        'title': title.trim(),
        'description': description.trim(),
        'postedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'category': category?.trim(),
        'imageUrls': imageUrls,
        'priority': priority,
        'isPinned': isPinned,
        'isUrgent': priority == 'urgent',
        'isImportant': priority == 'important',
        'tags': tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList(),
        'views': 0,
        
        // Keep old imageUrl for backward compatibility
        if (imageUrls.isNotEmpty) 'imageUrl': imageUrls.first,
      };

      await _firestore.collection('announcements').add(announcementData);
      if (kDebugMode) {
        print('Announcement created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating announcement: $e');
      }
      throw Exception('Failed to create announcement: ${e.toString()}');
    }
  }

  /// Update announcement with enhanced error handling
  Future<void> updateAnnouncement({
    required String id,
    required String title,
    required String description,
    required String? category,
    required List<String> currentImageUrls,
    required List<XFile>? newImageFiles,
    String priority = 'normal',
    bool isPinned = false,
    List<String> tags = const [],
  }) async {
    try {
      // Validate input
      if (title.trim().isEmpty) {
        throw ArgumentError('Title cannot be empty');
      }
      if (description.trim().isEmpty) {
        throw ArgumentError('Description cannot be empty');
      }

      List<String> finalImageUrls = List.from(currentImageUrls);
      
      // Delete old images and upload new ones
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        if (kDebugMode) {
          print('Replacing images - deleting old ones from Cloudinary...');
        }
        
        // Delete existing images from Cloudinary
        if (currentImageUrls.isNotEmpty) {
          await _cloudinaryService.deleteMultipleImages(currentImageUrls);
        }
        
        // Upload new images
        finalImageUrls.clear();
        final maxImages = 5;
        final imagesToUpload = newImageFiles.take(maxImages).toList();
        
        if (kDebugMode) {
          print('Uploading ${imagesToUpload.length} new images to Cloudinary...');
        }
        
        for (int i = 0; i < imagesToUpload.length; i++) {
          final file = imagesToUpload[i];
          
          // Validate file size (limit to 5MB)
          final fileSize = await File(file.path).length();
          if (fileSize > 5 * 1024 * 1024) {
            throw Exception('Image ${i + 1} is too large. Maximum size is 5MB.');
          }
          
          try {
            final imageUrl = await _cloudinaryService.uploadImage(file);
            finalImageUrls.add(imageUrl);
            if (kDebugMode) {
              print('Successfully uploaded new image ${i + 1}');
            }
          } catch (e) {
            if (kDebugMode) {
              print('Failed to upload new image ${i + 1}: $e');
            }
          }
        }
        
        if (kDebugMode) {
          print('Successfully updated images');
        }
      }

      // Update announcement
      final updateData = {
        'title': title.trim(),
        'description': description.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'category': category?.trim(),
        'imageUrls': finalImageUrls,
        'priority': priority,
        'isPinned': isPinned,
        'isUrgent': priority == 'urgent',
        'isImportant': priority == 'important',
        'tags': tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList(),
        
        // Keep old imageUrl for backward compatibility
        if (finalImageUrls.isNotEmpty) 'imageUrl': finalImageUrls.first,
      };

      await _firestore.collection('announcements').doc(id).update(updateData);
      if (kDebugMode) {
        print('Announcement updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating announcement: $e');
      }
      throw Exception('Failed to update announcement: ${e.toString()}');
    }
  }

  /// Get announcements with enhanced error handling
  Stream<List<Announcement>> getAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('isPinned', descending: true)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final announcements = <Announcement>[];
          
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              final announcement = Announcement.fromJson(
                {...data, 'id': doc.id},
                doc.id,
              );
              announcements.add(announcement);
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing announcement ${doc.id}: $e');
              }
              // Continue with other announcements
            }
          }
          
          return announcements;
        })
        .handleError((error) {
          if (kDebugMode) {
            print('Error in announcements stream: $error');
          }
          return <Announcement>[]; // Return empty list on error
        });
  }

  /// Delete announcement with enhanced cleanup
  Future<void> deleteAnnouncement(String id, List<String> imageUrls) async {
    try {
      if (kDebugMode) {
        print('Deleting announcement and its images...');
      }
      
      // Delete all images from Cloudinary
      if (imageUrls.isNotEmpty) {
        if (kDebugMode) {
          print('Deleting ${imageUrls.length} images from Cloudinary...');
        }
        await _cloudinaryService.deleteMultipleImages(imageUrls);
        if (kDebugMode) {
          print('Successfully processed image deletion from Cloudinary');
        }
      }
      
      // Delete the document from Firebase
      await _firestore.collection('announcements').doc(id).delete();
      if (kDebugMode) {
        print('Announcement deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting announcement: $e');
      }
      throw Exception('Failed to delete announcement: ${e.toString()}');
    }
  }

  /// Update view count safely
  Future<void> incrementViewCount(String announcementId) async {
    try {
      await _firestore.collection('announcements').doc(announcementId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to increment view count: $e');
      }
      // Fail silently for view counts
    }
  }

  /// Toggle pin status
  Future<void> togglePinStatus(String announcementId, bool isPinned) async {
    try {
      await _firestore.collection('announcements').doc(announcementId).update({
        'isPinned': isPinned,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating pin status: $e');
      }
      throw Exception('Failed to update pin status: ${e.toString()}');
    }
  }

  /// Update priority
  Future<void> updatePriority(String announcementId, String priority) async {
    try {
      final validPriorities = ['normal', 'important', 'urgent'];
      if (!validPriorities.contains(priority)) {
        throw ArgumentError('Invalid priority: $priority');
      }
      
      await _firestore.collection('announcements').doc(announcementId).update({
        'priority': priority,
        'isUrgent': priority == 'urgent',
        'isImportant': priority == 'important',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating priority: $e');
      }
      throw Exception('Failed to update priority: ${e.toString()}');
    }
  }

  /// Get announcements by category
  Stream<List<Announcement>> getAnnouncementsByCategory(String category) {
    return _firestore
        .collection('announcements')
        .where('category', isEqualTo: category)
        .orderBy('isPinned', descending: true)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final announcements = <Announcement>[];
          
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              final announcement = Announcement.fromJson(
                {...data, 'id': doc.id},
                doc.id,
              );
              announcements.add(announcement);
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing announcement ${doc.id}: $e');
              }
            }
          }
          
          return announcements;
        })
        .handleError((error) {
          if (kDebugMode) {
            print('Error in category announcements stream: $error');
          }
          return <Announcement>[];
        });
  }

  /// Search announcements with enhanced filtering
  Stream<List<Announcement>> searchAnnouncements(String searchTerm) {
    return _firestore
        .collection('announcements')
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final announcements = <Announcement>[];
          final lowerSearchTerm = searchTerm.toLowerCase();
          
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              final announcement = Announcement.fromJson(
                {...data, 'id': doc.id},
                doc.id,
              );
              
              // Enhanced search criteria
              final matchesTitle = announcement.title.toLowerCase().contains(lowerSearchTerm);
              final matchesDescription = announcement.description.toLowerCase().contains(lowerSearchTerm);
              final matchesCategory = announcement.category?.toLowerCase().contains(lowerSearchTerm) ?? false;
              final matchesTags = announcement.tags.any((tag) => tag.toLowerCase().contains(lowerSearchTerm));
              
              if (matchesTitle || matchesDescription || matchesCategory || matchesTags) {
                announcements.add(announcement);
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing announcement ${doc.id}: $e');
              }
            }
          }
          
          return announcements;
        })
        .handleError((error) {
          if (kDebugMode) {
            print('Error in search announcements stream: $error');
          }
          return <Announcement>[];
        });
  }

  /// Get announcement by ID
  Future<Announcement?> getAnnouncementById(String id) async {
    try {
      final doc = await _firestore.collection('announcements').doc(id).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        return Announcement.fromJson(
          {...data, 'id': doc.id},
          doc.id,
        );
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting announcement by ID: $e');
      }
      return null;
    }
  }

  /// Get optimized image URL with Cloudinary transformations
  String getOptimizedImageUrl(String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    return _cloudinaryService.getOptimizedImageUrl(
      originalUrl,
      width: width,
      height: height,
      quality: quality,
      format: format,
    );
  }
}
