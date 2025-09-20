import 'package:flutter/material.dart';
import '../services/gemini_match_service.dart';

class MatchScreen extends StatefulWidget {
	@override
	_MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
	String? matchScore;
	bool isLoading = false;

	Future<void> fetchMatchScore() async {
		setState(() { isLoading = true; });
		final prompt = '''
Given the following offer and request, rate the match from 0 (poor) to 1 (excellent):

Offer:
- Company: TestCo
- Keywords: steel, plastic, aluminum
- Location: NY
- Quantity: 50
- Compound: Polyethylene
- Date: 2025-09-01
- Reputation: 4.5

Request:
- Company: TestReq
- Keywords: aluminum, steel, glass
- Location: LA
- Quantity: 40
- Compound: Polypropylene
- Date: 2025-09-10
- Reputation: 4.0

What is the match score?
''';
		final score = await getGeminiMatchScore(prompt);
		setState(() {
			matchScore = score;
			isLoading = false;
		});
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: Text('Gemini Matchmaking')),
			body: Padding(
				padding: const EdgeInsets.all(16.0),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						ElevatedButton(
							onPressed: isLoading ? null : fetchMatchScore,
							child: Text(isLoading ? 'Loading...' : 'Get Match Score'),
						),
						SizedBox(height: 24),
						Text(
							matchScore != null
									? 'Match Score: $matchScore'
									: 'Press the button to get a match score.',
							style: TextStyle(fontSize: 18),
						),
					],
				),
			),
		);
	}
}
