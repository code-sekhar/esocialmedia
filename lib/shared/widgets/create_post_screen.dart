import 'dart:io';
import '../../features/social/social_api.dart';
import '../../core/auth/auth_scope.dart';
import '../../core/l10n/auth_copy.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostScreen extends StatefulWidget {
  final SocialPost? post;
  const CreatePostScreen({super.key, this.post});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  // =========================================================
  // CONTROLLER
  // =========================================================

  final TextEditingController postController = TextEditingController();

  // =========================================================
  // IMAGE PICKER
  // =========================================================

  final ImagePicker _picker = ImagePicker();

  // =========================================================
  // SELECTED MEDIA
  // =========================================================

  final List<XFile> selectedPhotos = [];

  final List<XFile> selectedVideos = [];

  // =========================================================
  // POSTING
  // =========================================================

  bool isPosting = false;
  String visibility = 'PRIVATE';
  @override
  void initState() {
    super.initState();
    postController.text = widget.post?.content ?? '';
    visibility = widget.post?.visibility ?? 'PRIVATE';
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    postController.dispose();
    super.dispose();
  }

  // =========================================================
  // PICK MULTIPLE PHOTOS
  // =========================================================

  Future<void> _pickPhotos() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);

      if (images.isEmpty || !mounted) return;

      setState(() {
        selectedPhotos.addAll(images);
      });

      debugPrint('Selected photos: ${selectedPhotos.length}');
    } catch (e) {
      debugPrint('Photo picker error: $e');
    }
  }

  // =========================================================
  // PICK VIDEO
  // =========================================================

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

      if (video == null || !mounted) return;

      setState(() {
        selectedVideos.add(video);
      });

      debugPrint('Selected videos: ${selectedVideos.length}');
    } catch (e) {
      debugPrint('Video picker error: $e');
    }
  }

  // =========================================================
  // REMOVE PHOTO
  // =========================================================

  void _removePhoto(int index) {
    if (index < 0 || index >= selectedPhotos.length) {
      return;
    }

    setState(() {
      selectedPhotos.removeAt(index);
    });
  }

  // =========================================================
  // REMOVE VIDEO
  // =========================================================

  void _removeVideo(int index) {
    if (index < 0 || index >= selectedVideos.length) {
      return;
    }

    setState(() {
      selectedVideos.removeAt(index);
    });
  }

  // =========================================================
  // HAS MEDIA
  // =========================================================

  bool get hasMedia {
    return selectedPhotos.isNotEmpty || selectedVideos.isNotEmpty;
  }

  // =========================================================
  // PHOTO / VIDEO SELECT
  // =========================================================

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.white,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                // =============================================
                // TITLE
                // =============================================
                const Text(
                  'Add to your post',

                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 20),

                // =============================================
                // PHOTO
                // =============================================
                ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,

                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.green,
                    ),
                  ),

                  title: const Text(
                    'Photo',

                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),

                  subtitle: const Text('Choose multiple photos from gallery'),

                  onTap: () {
                    Navigator.pop(context);

                    _pickPhotos();
                  },
                ),

                // =============================================
                // VIDEO
                // =============================================
                ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,

                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.video_library_outlined,
                      color: Colors.red,
                    ),
                  ),

                  title: const Text(
                    'Video',

                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),

                  subtitle: const Text('Choose a video from gallery'),

                  onTap: () {
                    Navigator.pop(context);

                    _pickVideo();
                  },
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // CREATE POST
  // =========================================================

  Future<void> _createPost() async {
    if (isPosting) return;
    final text = postController.text.trim();
    if (text.isEmpty || text.runes.length > 3000 || hasMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Use 1–3000 text characters. Attachments are previews only and cannot be published.',
          ),
        ),
      );
      return;
    }
    setState(() => isPosting = true);
    try {
      final api = SocialApi(AuthScope.of(context));
      final post = widget.post;
      if (post == null) {
        await api.create(text, visibility);
      } else {
        await api.edit(post, text, visibility);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AuthCopy.error(e)} Refresh before retrying an uncertain change.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isPosting = false);
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return ProtectedSession(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),

        // =======================================================
        // APP BAR
        // =======================================================
        appBar: AppBar(
          backgroundColor: Colors.white,

          elevation: 0,

          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),

            onPressed: () {
              Navigator.pop(context);
            },
          ),

          title: Text(
            widget.post == null ? 'Create Post' : 'Edit Post',

            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),

              child: GestureDetector(
                onTap: isPosting ? null : _createPost,

                child: Container(
                  width: 65,

                  alignment: Alignment.center,

                  decoration: BoxDecoration(
                    color: isPosting ? Colors.grey : const Color(0xFFB83D72),

                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: isPosting
                      ? const SizedBox(
                          width: 16,
                          height: 16,

                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Post',

                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),

        // =======================================================
        // BODY
        // =======================================================
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Text(
                'Text-only posting. Public shares text and username with signed-in members. Birth inputs stay private. Media/feeling/astrology tools below are unsaved design previews.',
              ),
              DropdownButtonFormField<String>(
                initialValue: visibility,
                decoration: const InputDecoration(labelText: 'Audience'),
                items: const [
                  DropdownMenuItem(
                    value: 'PRIVATE',
                    child: Text('Private · only you'),
                  ),
                  DropdownMenuItem(
                    value: 'PUBLIC',
                    child: Text('Public · signed-in members'),
                  ),
                ],
                onChanged: isPosting
                    ? null
                    : (value) =>
                          setState(() => visibility = value ?? 'PRIVATE'),
              ),

              // =================================================
              // USER
              // =================================================
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,

                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE0E0E0),
                    ),

                    child: const Icon(Icons.person, color: Colors.grey),
                  ),

                  const SizedBox(width: 10),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        AuthScope.of(context).account?.displayName ??
                            AuthScope.of(context).account?.username ??
                            'Your account',

                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: 3),

                      Text(
                        visibility,

                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // =================================================
              // TEXT FIELD
              // =================================================
              Container(
                width: double.infinity,

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(12),

                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),

                child: TextField(
                  controller: postController,

                  maxLength: 3000,
                  maxLines: 8,
                  minLines: 6,

                  decoration: const InputDecoration(
                    hintText: "What's aligning today?",

                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),

                    border: InputBorder.none,

                    contentPadding: EdgeInsets.all(15),
                  ),

                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // =================================================
              // MEDIA PREVIEW
              // =================================================
              if (hasMedia) _mediaPreview(),

              if (hasMedia) const SizedBox(height: 15),

              // =================================================
              // OPTIONS
              // =================================================
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(12),
                ),

                child: Column(
                  children: [
                    _option(
                      icon: Icons.photo_library_outlined,

                      title: 'Photo / Video',

                      onTap: _showMediaPicker,
                    ),

                    _option(
                      icon: Icons.videocam_outlined,

                      title: 'Live Video',

                      onTap: () {
                        debugPrint('Start live');
                      },
                    ),

                    _option(
                      icon: Icons.auto_awesome,

                      title: 'Feeling / Activity',

                      onTap: () {
                        debugPrint('Feeling / Activity');
                      },
                    ),

                    _option(
                      icon: Icons.auto_graph,

                      title: 'Astrology',

                      onTap: () {
                        debugPrint('Astrology');
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // =================================================
              // CREATE POST
              // =================================================
              SizedBox(
                width: double.infinity,
                height: 48,

                child: ElevatedButton(
                  onPressed: isPosting ? null : _createPost,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB83D72),

                    disabledBackgroundColor: Colors.grey,

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  child: isPosting
                      ? const SizedBox(
                          width: 20,
                          height: 20,

                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.post == null ? 'Create Post' : 'Save changes',

                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // MEDIA PREVIEW
  // =========================================================

  Widget _mediaPreview() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // =================================================
          // HEADER
          // =================================================
          Row(
            children: [
              const Text(
                'Selected Media',

                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),

              const Spacer(),

              Text(
                '${selectedPhotos.length + selectedVideos.length} items',

                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // =================================================
          // PHOTOS
          // =================================================
          if (selectedPhotos.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,

              physics: const NeverScrollableScrollPhysics(),

              itemCount: selectedPhotos.length,

              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,

                crossAxisSpacing: 6,

                mainAxisSpacing: 6,

                childAspectRatio: 1,
              ),

              itemBuilder: (context, index) {
                final photo = selectedPhotos[index];

                return Stack(
                  fit: StackFit.expand,

                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),

                      child: Image.file(File(photo.path), fit: BoxFit.cover),
                    ),

                    // REMOVE
                    Positioned(
                      top: 5,
                      right: 5,

                      child: _removeButton(
                        onTap: () {
                          _removePhoto(index);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),

          // =================================================
          // VIDEO
          // =================================================
          if (selectedVideos.isNotEmpty) const SizedBox(height: 8),

          if (selectedVideos.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,

              physics: const NeverScrollableScrollPhysics(),

              itemCount: selectedVideos.length,

              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,

                crossAxisSpacing: 6,

                mainAxisSpacing: 6,

                childAspectRatio: 1,
              ),

              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,

                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF222222),

                        borderRadius: BorderRadius.circular(8),
                      ),

                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline,

                          color: Colors.white,

                          size: 40,
                        ),
                      ),
                    ),

                    // VIDEO LABEL
                    Positioned(
                      left: 5,
                      bottom: 5,

                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.black54,

                          borderRadius: BorderRadius.circular(5),
                        ),

                        child: const Text(
                          'VIDEO',

                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // REMOVE
                    Positioned(
                      top: 5,
                      right: 5,

                      child: _removeButton(
                        onTap: () {
                          _removeVideo(index);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // =========================================================
  // REMOVE BUTTON
  // =========================================================

  Widget _removeButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: 26,
        height: 26,

        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),

        child: const Icon(Icons.close, color: Colors.white, size: 16),
      ),
    );
  }

  // =========================================================
  // OPTION
  // =========================================================

  Widget _option({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),

        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF8F19E8)),

            const SizedBox(width: 12),

            Text(
              title,

              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),

            const Spacer(),

            const Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
