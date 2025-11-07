import 'package:avatar_plus/avatar_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:passage/models/user.dart';

class AvatarPickerDialog extends StatefulWidget {
  const AvatarPickerDialog({
    required this.currentUser,
    required this.onAvatarSelected,
    required this.initialSeed,
  });

  final User currentUser;
  final Function(String) onAvatarSelected;
  final String initialSeed;

  @override
  State<AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<AvatarPickerDialog> {
  late TextEditingController _seedController;
  String _currentSeed = '';
  final List<String> _predefinedSeeds = [
    'avatar_space_cat',
    'avatar_robot',
    'avatar_unicorn',
    'avatar_dragon',
    'avatar_penguin',
    'avatar_owl',
  ];

  @override
  void initState() {
    super.initState();
    _currentSeed = widget.initialSeed;
    _seedController = TextEditingController(text: widget.initialSeed);
    _seedController.addListener(() {
      setState(() {
        _currentSeed = _seedController.text.trim().isEmpty
            ? widget.currentUser.username
            : _seedController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  void _generateRandomSeed() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    _seedController.text = 'user_$random';
  }

  void _selectSeed(String seed) {
    _seedController.text = seed;
  }

  void _confirmSelection() {
    final selectedSeed = _seedController.text.trim().isEmpty
        ? widget.currentUser.username
        : _seedController.text.trim();
    widget.onAvatarSelected(selectedSeed);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: EdgeInsets.all(24.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose Your Avatar',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Text(
                'Enter any text to generate a unique avatar. The same text always generates the same avatar.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 24.h),
              // Avatar Preview
              Center(
                child: Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: AvatarPlus(
                      _currentSeed,
                      width: 120.w,
                      height: 120.w,
                      trBackground: true,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              // Text Input
              TextField(
                controller: _seedController,
                decoration: InputDecoration(
                  labelText: 'Avatar Seed',
                  hintText: 'Enter any text...',
                  prefixIcon: const Icon(Icons.edit),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.shuffle),
                    onPressed: _generateRandomSeed,
                    tooltip: 'Generate random seed',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Tip: Use your name, a word, or click shuffle for a random avatar',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11.sp,
                ),
              ),
              SizedBox(height: 24.h),
              // Predefined Seeds Section
              Text(
                'Quick Picks',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                height: 80.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _predefinedSeeds.length,
                  separatorBuilder: (context, index) => SizedBox(width: 12.w),
                  itemBuilder: (context, index) {
                    final seed = _predefinedSeeds[index];
                    final isSelected = _currentSeed == seed;
                    return GestureDetector(
                      onTap: () => _selectSeed(seed),
                      child: Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.2),
                            width: isSelected ? 3 : 2,
                          ),
                        ),
                        child: ClipOval(
                          child: AvatarPlus(
                            seed,
                            width: 80.w,
                            height: 80.w,
                            trBackground: true,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 24.h),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: const Text('Save Avatar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
