import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/candidates/logic/candidate_offer_card_logic.dart';
import 'package:opti_job_app/modules/candidates/models/candidate_offer_card_models.dart';

void main() {
  test('keeps card border width stable when hover decoration is applied', () {
    const palette = CandidateOfferCardPalette(
      ink: Colors.black,
      muted: Colors.grey,
      borderColor: Colors.blueGrey,
      surfaceColor: Colors.white,
      backgroundColor: Colors.white,
      gradient: LinearGradient(colors: [Colors.white, Colors.black]),
      tagBackgroundColor: Colors.white,
      tagBorderColor: Colors.grey,
      tagTextColor: Colors.black,
    );

    final normalDecoration = CandidateOfferCardLogic.resolveDecoration(
      palette: palette,
      isDark: false,
      isHovered: false,
    );
    final hoveredDecoration = CandidateOfferCardLogic.resolveDecoration(
      palette: palette,
      isDark: false,
      isHovered: true,
    );

    expect(normalDecoration.borderWidth, 1);
    expect(hoveredDecoration.borderWidth, 1);
    expect(hoveredDecoration.borderColor, isNot(normalDecoration.borderColor));
  });

  test(
    'resolves hover overlay gradient with visible accent in both themes',
    () {
      final darkGradient = CandidateOfferCardLogic.resolveHoverOverlayGradient(
        isDark: true,
      );
      final lightGradient = CandidateOfferCardLogic.resolveHoverOverlayGradient(
        isDark: false,
      );

      expect(darkGradient.colors.length, 2);
      expect(lightGradient.colors.length, 2);
      expect(darkGradient.colors.first.a, greaterThan(0));
      expect(lightGradient.colors.first.a, greaterThan(0));
      expect(darkGradient.colors.first, isNot(lightGradient.colors.first));
    },
  );
}
