import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const AIModerationApp());
}

class AIModerationApp extends StatelessWidget {
  const AIModerationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Moderation Demo',
      theme: ThemeData(),
      home: const ModerationDemoPage(),
    );
  }
}

// CSV Data Loader
class TrainingData {
  static Future<List<Map<String, String>>> load() async {
    try {
      String csv = await rootBundle.loadString('assets/tweet_sentiment.csv');
      List<String> lines = csv.split('\n');
      List<Map<String, String>> data = [];
      
      // Skip the first line and process each line
      for (int i = 1; i < lines.length; i++) {
        String line = lines[i];
        if (line.isNotEmpty) {
          List<String> parts = line.split(',');
          Map<String, String> row = {
            'tweet': parts[0].trim(),
            'sentiment': parts[1].trim(),
          };
          data.add(row);
        }
      }
      return data;
    } catch (e) {
      return [];
    }
  }
}

// Association Rule 
class AssociationRule {
  List<String> antecedents; // Words
  String consequent; // Sentiment
  double support;
  double confidence;
  double lift;

  AssociationRule({
    required this.antecedents,
    required this.consequent,
    required this.support,
    required this.confidence,
    required this.lift,
  });

  @override
  String toString() {
    String words = antecedents.join(', ');
    String conf = confidence.toStringAsFixed(2);
    String liftStr = lift.toStringAsFixed(2);
    return '{$words} → $consequent (conf: $conf, lift: $liftStr)';
  }
}

// Frequent Itemset for Apriori algorithm
class FrequentItemset {
  List<String> items;
  double support;

  FrequentItemset({required this.items, required this.support});
}

// Main sentiment analyzer using Association Rule Mining
class SentimentModerator {
  List<AssociationRule>? _rules;
  bool _isTrained = false;

  // Stop words to ignore
  static List<String> stopWords = [
    'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
    'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'been', 'be',
    'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'should',
    'could', 'may', 'might', 'must', 'can', 'this', 'that', 'these',
    'those', 'i', 'you', 'he', 'she', 'it', 'we', 'they', 'my', 'your',
    'his', 'her', 'its', 'our', 'their', 'me', 'him', 'them', 'us',
  ];

  // Harmful words that require moderation
  static List<String> toxicWords = [
    'kill', 'death', 'violent', 'attack', 'threat', 'harm', 'abuse',
    'offensive', 'racist', 'sexist', 'discriminate',
  ];

  // Preprocess text, lowercase and remove punctuation
  static List<String> preprocessText(String text) {
    // Make lowercase
    String lowerText = text.toLowerCase();
    
    // Remove punctuation
    String cleanText = lowerText.replaceAll(RegExp(r'[^\w\s]'), ' ');
    
    // Split into words
    List<String> allWords = cleanText.split(RegExp(r'\s+'));
    
    // Filter out short words and stop words
    List<String> goodWords = [];
    for (String word in allWords) {
      if (word.length > 2) {
        bool isStopWord = false;
        for (String stopWord in stopWords) {
          if (word == stopWord) {
            isStopWord = true;
            break;
          }
        }
        if (!isStopWord) {
          goodWords.add(word);
        }
      }
    }
    
    return goodWords;
  }

  // Train using Apriori algorithm
  Future<void> train({
    double minSupport = 0.03,
    double minConfidence = 0.3,
    double minLift = 1.0,
  }) async {
    // Load the training data
    List<Map<String, String>> dataset = await TrainingData.load();
    
    // Create transactions (each row becomes a list of words + sentiment)
    List<List<String>> transactions = [];
    for (Map<String, String> row in dataset) {
      List<String> words = preprocessText(row['tweet']!);
      List<String> transaction = [];
      
      // Add all words
      for (String word in words) {
        transaction.add(word);
      }
      
      // Add sentiment as an item
      transaction.add('sentiment_${row['sentiment']}');
      transactions.add(transaction);
    }

    // Find frequent itemsets using Apriori
    List<FrequentItemset> itemsets = _apriori(transactions, minSupport);
    
    // Generate association rules from itemsets
    List<AssociationRule> allRules = _generateRules(
      itemsets,
      transactions,
      minConfidence,
      minLift,
    );

    // Filter rules to only keep sentiment prediction rules
    List<AssociationRule> filteredRules = [];
    for (AssociationRule rule in allRules) {
      // Only keep rules where consequence is a sentiment
      if (rule.consequent.startsWith('sentiment_')) {
        // Check that antecedents don't contain sentiment
        bool hasOnlyWords = true;
        for (String ant in rule.antecedents) {
          if (ant.startsWith('sentiment_')) {
            hasOnlyWords = false;
            break;
          }
        }
        
        if (hasOnlyWords) {
          filteredRules.add(rule);
        }
      }
    }

    // Sort rules by lift (best rules first), then by confidence
    for (int i = 0; i < filteredRules.length; i++) {
      for (int j = i + 1; j < filteredRules.length; j++) {
        bool shouldSwap = false;
        if (filteredRules[j].lift > filteredRules[i].lift) {
          shouldSwap = true;
        } else if (filteredRules[j].lift == filteredRules[i].lift) {
          if (filteredRules[j].confidence > filteredRules[i].confidence) {
            shouldSwap = true;
          }
        }
        
        if (shouldSwap) {
          AssociationRule temp = filteredRules[i];
          filteredRules[i] = filteredRules[j];
          filteredRules[j] = temp;
        }
      }
    }

    _rules = filteredRules;
    _isTrained = true;
  }

  // Apriori algorithm to find frequent itemsets
  List<FrequentItemset> _apriori(
    List<List<String>> transactions,
    double minSupport,
  ) {
    int totalTransactions = transactions.length;
    List<FrequentItemset> allFrequentItemsets = [];

    // Step 1: Count each individual item
    Map<String, int> itemCounts = {};
    for (List<String> transaction in transactions) {
      for (String item in transaction) {
        if (itemCounts.containsKey(item)) {
          itemCounts[item] = itemCounts[item]! + 1;
        } else {
          itemCounts[item] = 1;
        }
      }
    }

    // Step 2: Find frequent 1-itemsets (single items that appear often enough)
    List<FrequentItemset> currentItemsets = [];
    for (String item in itemCounts.keys) {
      int count = itemCounts[item]!;
      double support = count / totalTransactions;
      if (support >= minSupport) {
        FrequentItemset itemset = FrequentItemset(
          items: [item],
          support: support,
        );
        currentItemsets.add(itemset);
        allFrequentItemsets.add(itemset);
      }
    }

    // Step 3: Generate frequent 2-itemsets (pairs of items)
    List<FrequentItemset> pairItemsets = _generateCandidatePairs(
      currentItemsets,
      transactions,
      minSupport,
      totalTransactions,
    );
    
    for (FrequentItemset pair in pairItemsets) {
      allFrequentItemsets.add(pair);
    }

    return allFrequentItemsets;
  }

  // Generate candidate pairs and filter by support
  List<FrequentItemset> _generateCandidatePairs(
    List<FrequentItemset> singleItemsets,
    List<List<String>> transactions,
    double minSupport,
    int totalTransactions,
  ) {
    List<FrequentItemset> pairs = [];

    // Try all combinations of single items
    for (int i = 0; i < singleItemsets.length; i++) {
      for (int j = i + 1; j < singleItemsets.length; j++) {
        // Create a candidate pair
        List<String> candidate = [];
        
        // Add items from first itemset
        for (String item in singleItemsets[i].items) {
          candidate.add(item);
        }
        
        // Add items from second itemset
        for (String item in singleItemsets[j].items) {
          bool alreadyExists = false;
          for (String existing in candidate) {
            if (existing == item) {
              alreadyExists = true;
              break;
            }
          }
          if (!alreadyExists) {
            candidate.add(item);
          }
        }

        // Count how many transactions contain this candidate
        int count = 0;
        for (List<String> transaction in transactions) {
          bool hasAll = true;
          for (String item in candidate) {
            bool found = false;
            for (String transItem in transaction) {
              if (transItem == item) {
                found = true;
                break;
              }
            }
            if (!found) {
              hasAll = false;
              break;
            }
          }
          
          if (hasAll) {
            count++;
          }
        }

        double support = count / totalTransactions;
        if (support >= minSupport) {
          FrequentItemset pair = FrequentItemset(
            items: candidate,
            support: support,
          );
          pairs.add(pair);
        }
      }
    }

    return pairs;
  }

  // Generate association rules
  List<AssociationRule> _generateRules(
    List<FrequentItemset> itemsets,
    List<List<String>> transactions,
    double minConf,
    double minLift,
  ) {
    List<AssociationRule> rules = [];
    int total = transactions.length;

    // For each itemset with 2 or more items
    for (FrequentItemset itemset in itemsets) {
      if (itemset.items.length < 2) {
        continue;
      }

      // Try each item as the consequent
      for (String consequent in itemset.items) {
        // The rest are antecedents
        List<String> antecedents = [];
        for (String item in itemset.items) {
          if (item != consequent) {
            antecedents.add(item);
          }
        }

        if (antecedents.isEmpty) {
          continue;
        }

        // Count transactions that contain antecedents
        int antCount = 0;
        for (List<String> transaction in transactions) {
          bool hasAll = true;
          for (String ant in antecedents) {
            bool found = false;
            for (String transItem in transaction) {
              if (transItem == ant) {
                found = true;
                break;
              }
            }
            if (!found) {
              hasAll = false;
              break;
            }
          }
          if (hasAll) {
            antCount++;
          }
        }

        if (antCount == 0) {
          continue;
        }

        // Calculate confidence
        double confidence = itemset.support / (antCount / total);

        // Count transactions that contain consequent
        int consCount = 0;
        for (List<String> transaction in transactions) {
          bool found = false;
          for (String transItem in transaction) {
            if (transItem == consequent) {
              found = true;
              break;
            }
          }
          if (found) {
            consCount++;
          }
        }

        double consequentSupport = consCount / total;
        double lift = 0.0;
        if (consequentSupport > 0) {
          lift = confidence / consequentSupport;
        }

        // Only keep rules that meet minimum thresholds
        if (confidence >= minConf && lift >= minLift) {
          AssociationRule rule = AssociationRule(
            antecedents: antecedents,
            consequent: consequent,
            support: itemset.support,
            confidence: confidence,
            lift: lift,
          );
          rules.add(rule);
        }
      }
    }

    return rules;
  }

  String predictSentiment(String text) {
    if (!_isTrained || _rules == null) {
      return 'neutral';
    }

    List<String> words = preprocessText(text);
    Map<String, int> counts = {};

    // Check each rule
    for (AssociationRule rule in _rules!) {
      // See if all antecedents are in the text
      bool allMatch = true;
      for (String antecedent in rule.antecedents) {
        bool found = false;
        for (String word in words) {
          if (word == antecedent) {
            found = true;
            break;
          }
        }
        if (!found) {
          allMatch = false;
          break;
        }
      }

      if (allMatch) {
        String sentiment = rule.consequent.replaceAll('sentiment_', '');
        if (counts.containsKey(sentiment)) {
          counts[sentiment] = counts[sentiment]! + 1;
        } else {
          counts[sentiment] = 1;
        }
      }
    }

    if (counts.isEmpty) {
      return 'neutral';
    }

    // Find sentiment with highest count
    String bestSentiment = '';
    int maxCount = 0;
    for (String sentiment in counts.keys) {
      int count = counts[sentiment]!;
      if (count > maxCount) {
        maxCount = count;
        bestSentiment = sentiment;
      }
    }

    return bestSentiment;
  }

  bool containsToxicContent(String text) {
    List<String> words = preprocessText(text);
    
    for (String word in words) {
      for (String toxicWord in toxicWords) {
        if (word == toxicWord) {
          return true;
        }
      }
    }
    
    return false;
  }

  List<AssociationRule> getMatchedRules(String text) {
    if (!_isTrained || _rules == null) {
      return [];
    }

    List<String> words = preprocessText(text);
    List<AssociationRule> matched = [];

    for (AssociationRule rule in _rules!) {
      bool allMatch = true;
      for (String antecedent in rule.antecedents) {
        bool found = false;
        for (String word in words) {
          if (word == antecedent) {
            found = true;
            break;
          }
        }
        if (!found) {
          allMatch = false;
          break;
        }
      }

      if (allMatch) {
        matched.add(rule);
        if (matched.length >= 5) {
          break;
        }
      }
    }

    return matched;
  }

  ModerationResult moderateContent(String text) {
    String sentiment = predictSentiment(text);
    bool hasToxic = containsToxicContent(text);
    List<AssociationRule> rules = getMatchedRules(text);

    if (hasToxic) {
      return ModerationResult(
        text,
        sentiment,
        ModerationAction.blocked,
        'Contains toxic or harmful content',
        rules,
      );
    }

    if (sentiment == 'negative' && rules.isNotEmpty) {
      // Calculate average confidence
      double totalConf = 0.0;
      for (AssociationRule rule in rules) {
        totalConf = totalConf + rule.confidence;
      }
      double avgConf = totalConf / rules.length;

      String reason;
      if (avgConf > 0.7) {
        int percentage = (avgConf * 100).toInt();
        reason = 'Strong negative sentiment ($percentage%)';
      } else {
        reason = 'Negative sentiment detected';
      }

      return ModerationResult(
        text,
        sentiment,
        ModerationAction.flagged,
        reason,
        rules,
      );
    }

    return ModerationResult(
      text,
      sentiment,
      ModerationAction.approved,
      'Content appears safe',
      rules,
    );
  }

  List<AssociationRule>? get rules => _rules;
  bool get isTrained => _isTrained;
}

// Moderation action enum
enum ModerationAction { approved, flagged, blocked }

// Moderation Result
class ModerationResult {
  String text;
  String sentiment;
  String reason;
  ModerationAction action;
  List<AssociationRule> matchedRules;

  ModerationResult(
    this.text,
    this.sentiment,
    this.action,
    this.reason,
    this.matchedRules,
  );

  Color getActionColor() {
    if (action == ModerationAction.approved) {
      return Colors.green;
    } else if (action == ModerationAction.flagged) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData getActionIcon() {
    if (action == ModerationAction.approved) {
      return Icons.check_circle;
    } else if (action == ModerationAction.flagged) {
      return Icons.flag;
    } else {
      return Icons.block;
    }
  }

  String getActionText() {
    if (action == ModerationAction.approved) {
      return 'APPROVED';
    } else if (action == ModerationAction.flagged) {
      return 'FLAGGED';
    } else {
      return 'BLOCKED';
    }
  }

  Color get actionColor => getActionColor();
  IconData get actionIcon => getActionIcon();
  String get actionText => getActionText();
}

// Demo page showing the moderation system
class ModerationDemoPage extends StatefulWidget {
  const ModerationDemoPage({super.key});

  @override
  State<ModerationDemoPage> createState() => _ModerationDemoPageState();
}

class _ModerationDemoPageState extends State<ModerationDemoPage> {
  TextEditingController _textController = TextEditingController();
  SentimentModerator _moderator = SentimentModerator();
  ModerationResult? _result;
  bool _isTraining = false;
  bool _isModelTrained = false;

  // Sample test cases
  List<String> _sampleTexts = [
    "This product is absolutely fantastic!",
    "I'm really disappointed with the service",
    "The meeting starts at 3pm today",
    "I have two dollars in my pocket",
    "I miss sunny days",
    "This is absolutely my favorite restaurant of all time, I love eating here",
    "I hate looking for parking spots",
    "I loved cooking",
    "I love cooking",
    "I hate cooking, it sucks",
    "This is the worst experience ever, terrible service!",
    "Amazing food, beautiful ambiance, excellent staff!",
    "The venue is accessible and comfortable",
    "Never coming back here, awful place",
  ];

  @override
  void initState() {
    super.initState();
    _isTraining = true;
    
    // Train the model when the widget starts
    _moderator.train().then((value) {
      setState(() {
        _isTraining = false;
        _isModelTrained = true;
      });
    });
  }

  void _analyzeText() {
    if (_textController.text.isEmpty) {
      return;
    }
    if (!_isModelTrained) {
      return;
    }
    
    setState(() {
      _result = _moderator.moderateContent(_textController.text);
    });
  }

  void _testSamples() {
    if (!_isModelTrained) {
      return;
    }
    
    ModerationResult? lastResult;
    for (int i = 0; i < _sampleTexts.length; i++) {
      String text = _sampleTexts[i];
      lastResult = _moderator.moderateContent(text);
    }

    setState(() {
      if (lastResult != null) {
        _result = lastResult;
      }
    });
  }

  void _loadSample(String text) {
    setState(() {
      _textController.text = text;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Moderation Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog(context);
            },
            tooltip: 'About',
          ),
          IconButton(
            icon: const Icon(Icons.school),
            onPressed: _isModelTrained ? () {
              _showRulesDialog(context);
            } : null,
            tooltip: 'View Learned Rules',
          ),
        ],
      ),
      body: _isTraining
          ? const Center(child: Text('Training model...'))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text('Rules learned: ${_moderator.rules?.length ?? 0}'),
                const SizedBox(height: 12),
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Type text',
                  ),
                  maxLines: 3,
                  onSubmitted: (value) {
                    _analyzeText();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isModelTrained ? _analyzeText : null,
                        child: const Text('Analyze'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isModelTrained ? _testSamples : null,
                        child: const Text('Test Samples'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _textController.clear();
                      _result = null;
                    });
                  },
                  child: const Text('Clear Input'),
                ),
                _buildResultSection(),
                const SizedBox(height: 12),
                const Text('Sample Texts'),
                const SizedBox(height: 8),
                _buildSampleTextButtons(),
              ],
            ),
    );
  }

  Widget _buildResultSection() {
    if (_result != null) {
      return Column(
        children: [
          const SizedBox(height: 8),
          _buildResultCard(_result!),
        ],
      );
    } else {
      return Container();
    }
  }

  Widget _buildSampleTextButtons() {
    List<Widget> buttons = [];
    
    for (int i = 0; i < 5 && i < _sampleTexts.length; i++) {
      String text = _sampleTexts[i];
      Widget button = TextButton(
        onPressed: () {
          _loadSample(text);
        },
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
      buttons.add(button);
    }
    
    return Column(children: buttons);
  }

  Widget _buildResultCard(ModerationResult result) {
    // Build matched rules widgets
    List<Widget> ruleWidgets = [];
    if (result.matchedRules.isNotEmpty) {
      ruleWidgets.add(const SizedBox(height: 6));
      ruleWidgets.add(Text('Matched Rules (${result.matchedRules.length}):'));
      
      int rulesToShow = 3;
      if (result.matchedRules.length < 3) {
        rulesToShow = result.matchedRules.length;
      }
      
      for (int i = 0; i < rulesToShow; i++) {
        AssociationRule rule = result.matchedRules[i];
        String words = rule.antecedents.join(', ');
        String sentiment = rule.consequent.replaceAll('sentiment_', '');
        int confidence = (rule.confidence * 100).toInt();
        
        Widget ruleText = Text('- {$words} → $sentiment (conf: $confidence%)');
        ruleWidgets.add(ruleText);
      }
    }
    
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status: ${result.actionText}'),
          Text('Sentiment: ${result.sentiment.toUpperCase()}'),
          const SizedBox(height: 6),
          Text('Text: ${result.text}'),
          const SizedBox(height: 6),
          Text('Reason: ${result.reason}'),
          ...ruleWidgets,
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    int rulesCount = _moderator.rules?.length ?? 0;
    String message =
        'This demo uses tweet_sentiment.csv and Apriori rules for moderation.\n\n'
        'Actions:\n'
        'APPROVED: Safe content\n'
        'FLAGGED: Needs review\n'
        'BLOCKED: Harmful content\n\n'
        'Learned rules: $rulesCount';
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('About AI Moderation'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showRulesDialog(BuildContext context) {
    List<AssociationRule> rules = _moderator.rules ?? [];
    List<AssociationRule> topRules = [];
    
    int numToShow = 20;
    if (rules.length < 20) {
      numToShow = rules.length;
    }
    
    for (int i = 0; i < numToShow; i++) {
      topRules.add(rules[i]);
    }
    
    String content = '';
    for (int i = 0; i < topRules.length; i++) {
      AssociationRule rule = topRules[i];
      String words = rule.antecedents.join(', ');
      String sentiment = rule.consequent.replaceAll('sentiment_', '');
      String conf = (rule.confidence * 100).toStringAsFixed(1);
      String liftStr = rule.lift.toStringAsFixed(2);
      String support = (rule.support * 100).toStringAsFixed(1);
      
      content = content + '{$words} → $sentiment\n';
      content = content + 'Confidence: $conf% | Lift: $liftStr | Support: $support%';
      
      if (i < topRules.length - 1) {
        content = content + '\n\n';
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Learned Association Rules'),
          content: SingleChildScrollView(
            child: Text('Top ${topRules.length} rules:\n\n$content'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
