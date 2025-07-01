import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

enum ButtonType { primary, secondary, outline, text }
enum ButtonSize { small, medium, large }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null && !isLoading;
    
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? _getButtonHeight(),
      child: _buildButton(context, isDisabled),
    );
  }

  Widget _buildButton(BuildContext context, bool isDisabled) {
    switch (type) {
      case ButtonType.primary:
        return _buildPrimaryButton(context, isDisabled);
      case ButtonType.secondary:
        return _buildSecondaryButton(context, isDisabled);
      case ButtonType.outline:
        return _buildOutlineButton(context, isDisabled);
      case ButtonType.text:
        return _buildTextButton(context, isDisabled);
    }
  }

  Widget _buildPrimaryButton(BuildContext context, bool isDisabled) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled 
            ? Colors.grey.shade300 
            : backgroundColor ?? AppColors.primary,
        foregroundColor: isDisabled 
            ? Colors.grey.shade500 
            : textColor ?? Colors.white,
        elevation: isDisabled ? 0 : 2,
        shadowColor: AppColors.primary.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: _getHorizontalPadding(),
          vertical: _getVerticalPadding(),
        ),
      ),
      child: _buildButtonContent(context),
    );
  }

  Widget _buildSecondaryButton(BuildContext context, bool isDisabled) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled 
            ? Colors.grey.shade200 
            : backgroundColor ?? AppColors.secondary,
        foregroundColor: isDisabled 
            ? Colors.grey.shade500 
            : textColor ?? Colors.white,
        elevation: isDisabled ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: _getHorizontalPadding(),
          vertical: _getVerticalPadding(),
        ),
      ),
      child: _buildButtonContent(context),
    );
  }

  Widget _buildOutlineButton(BuildContext context, bool isDisabled) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: isDisabled 
            ? Colors.grey.shade500 
            : textColor ?? AppColors.primary,
        side: BorderSide(
          color: isDisabled 
              ? Colors.grey.shade300 
              : backgroundColor ?? AppColors.primary,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: _getHorizontalPadding(),
          vertical: _getVerticalPadding(),
        ),
      ),
      child: _buildButtonContent(context),
    );
  }

  Widget _buildTextButton(BuildContext context, bool isDisabled) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: isDisabled 
            ? Colors.grey.shade500 
            : textColor ?? AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: _getHorizontalPadding(),
          vertical: _getVerticalPadding(),
        ),
      ),
      child: _buildButtonContent(context),
    );
  }

  Widget _buildButtonContent(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: _getLoadingIndicatorSize(),
        height: _getLoadingIndicatorSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            type == ButtonType.outline || type == ButtonType.text
                ? AppColors.primary
                : Colors.white,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: AppSizes.spacingSmall),
          Text(
            text,
            style: _getTextStyle(context),
          ),
        ],
      );
    }

    return Text(
      text,
      style: _getTextStyle(context),
    );
  }

  double _getButtonHeight() {
    switch (size) {
      case ButtonSize.small:
        return 36;
      case ButtonSize.medium:
        return 48;
      case ButtonSize.large:
        return 56;
    }
  }

  double _getHorizontalPadding() {
    switch (size) {
      case ButtonSize.small:
        return AppSizes.paddingSmall;
      case ButtonSize.medium:
        return AppSizes.paddingMedium;
      case ButtonSize.large:
        return AppSizes.paddingLarge;
    }
  }

  double _getVerticalPadding() {
    return 0; // Height is controlled by button height
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  double _getLoadingIndicatorSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  TextStyle _getTextStyle(BuildContext context) {
    final baseStyle = switch (size) {
      ButtonSize.small => Theme.of(context).textTheme.bodySmall,
      ButtonSize.medium => Theme.of(context).textTheme.bodyMedium,
      ButtonSize.large => Theme.of(context).textTheme.bodyLarge,
    };

    return baseStyle?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ) ?? const TextStyle(fontWeight: FontWeight.w600);
  }
}

// Convenience constructors
class PrimaryButton extends CustomButton {
  const PrimaryButton({
    super.key,
    required super.text,
    super.onPressed,
    super.size = ButtonSize.medium,
    super.isLoading = false,
    super.icon,
    super.width,
    super.height,
  }) : super(type: ButtonType.primary);
}

class SecondaryButton extends CustomButton {
  const SecondaryButton({
    super.key,
    required super.text,
    super.onPressed,
    super.size = ButtonSize.medium,
    super.isLoading = false,
    super.icon,
    super.width,
    super.height,
  }) : super(type: ButtonType.secondary);
}

class OutlineButton extends CustomButton {
  const OutlineButton({
    super.key,
    required super.text,
    super.onPressed,
    super.size = ButtonSize.medium,
    super.isLoading = false,
    super.icon,
    super.width,
    super.height,
  }) : super(type: ButtonType.outline);
}

class TextOnlyButton extends CustomButton {
  const TextOnlyButton({
    super.key,
    required super.text,
    super.onPressed,
    super.size = ButtonSize.medium,
    super.isLoading = false,
    super.icon,
    super.width,
    super.height,
  }) : super(type: ButtonType.text);
}