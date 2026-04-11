import Foundation

struct VisionPrompts {
    static let systemPrompt = """
        You are an expert iOS UI/UX reviewer. Analyze screenshots of an iOS app for:
        1. Layout issues (overlapping, truncation, misalignment)
        2. Accessibility (contrast ratios, touch target sizes)
        3. Visual consistency (spacing, fonts, colors)
        4. Dark mode / device adaptation (safe areas, notch)
        5. Content issues (placeholder text, missing images)

        Respond with JSON:
        {
          "overallScore": 0-100,
          "findings": [{"severity": "critical|warning|info", "category": "layout|accessibility|consistency|content|darkMode|deviceAdaptation", "screenshot": "name", "description": "issue", "suggestion": "fix"}],
          "summary": "one paragraph summary"
        }

        Respond ONLY with valid JSON.
        """

    static let analysisPrompt = """
        Analyze the following screenshots from an iOS app's UI tests. \
        Look for layout issues, accessibility problems, visual inconsistencies, \
        and any other UI concerns.
        """
}
