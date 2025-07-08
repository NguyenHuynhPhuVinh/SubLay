import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../core/utils/responsive_helper.dart';
import '../modules/main_screen/controllers/main_screen_controller.dart';

class DesktopSidebar extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const DesktopSidebar({
    Key? key,
    this.isCollapsed = false,
    this.onToggleCollapse,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainScreenController>();
    final theme = Theme.of(context);
    
    return Container(
      width: isCollapsed 
          ? ResponsiveHelper.sidebarCollapsedWidth 
          : ResponsiveHelper.sidebarWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context, theme),
          Expanded(
            child: _buildNavigationItems(context, theme, controller),
          ),
          _buildFooter(context, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.video_play,
              color: theme.colorScheme.onPrimary,
              size: 24,
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'DuTupSRT',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Subtitle Editor',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (onToggleCollapse != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onToggleCollapse,
              icon: Icon(
                isCollapsed ? Iconsax.arrow_right_3 : Iconsax.arrow_left_3,
                size: 20,
              ),
              tooltip: isCollapsed ? 'Mở rộng' : 'Thu gọn',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationItems(
    BuildContext context, 
    ThemeData theme, 
    MainScreenController controller,
  ) {
    final navItems = [
      _NavItem(
        icon: Iconsax.video,
        label: 'Video Input',
        index: 0,
      ),
      _NavItem(
        icon: Iconsax.edit,
        label: 'Subtitle Editor',
        index: 1,
      ),
      _NavItem(
        icon: Iconsax.clock,
        label: 'Recent Videos',
        index: 2,
      ),
      _NavItem(
        icon: Iconsax.message_text,
        label: 'AI Prompts',
        index: 3,
      ),
      _NavItem(
        icon: Iconsax.setting_2,
        label: 'Settings',
        index: 4,
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: navItems.length,
      itemBuilder: (context, index) {
        final item = navItems[index];
        return Obx(() => _buildNavItem(
          context,
          theme,
          item,
          controller.currentIndex.value == item.index,
          () => controller.changeTabIndex(item.index),
        ));
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    ThemeData theme,
    _NavItem item,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected 
                  ? Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 24,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.8),
                        fontWeight: isSelected 
                            ? FontWeight.w600 
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Iconsax.user,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'User',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Desktop Mode',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}
