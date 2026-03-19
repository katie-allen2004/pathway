import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  List<String> antecedents;
  String consequent;
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
}

// Frequent Itemset for Apriori algorithm
class FrequentItemset {
  List<String> items;
  double support;

  FrequentItemset({required this.items, required this.support});
}

// Main sentiment analyzer using Association Rule Mining
class ReviewModerator {
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
    String lowerText = text.toLowerCase();
    String cleanText = lowerText.replaceAll(RegExp(r'[^\w\s]'), ' ');
    List<String> allWords = cleanText.split(RegExp(r'\s+'));

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
    List<Map<String, String>> dataset = await TrainingData.load();

    List<List<String>> transactions = [];
    for (Map<String, String> row in dataset) {
      List<String> words = preprocessText(row['tweet']!);
      List<String> transaction = [];

      for (String word in words) {
        transaction.add(word);
      }

      transaction.add('sentiment_${row['sentiment']}');
      transactions.add(transaction);
    }

    List<FrequentItemset> itemsets = _apriori(transactions, minSupport);

    List<AssociationRule> allRules = _generateRules(
      itemsets,
      transactions,
      minConfidence,
      minLift,
    );

    List<AssociationRule> filteredRules = [];
    for (AssociationRule rule in allRules) {
      if (rule.consequent.startsWith('sentiment_')) {
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

    // Sort rules by lift, then confidence
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

    for (int i = 0; i < singleItemsets.length; i++) {
      for (int j = i + 1; j < singleItemsets.length; j++) {
        List<String> candidate = [];

        for (String item in singleItemsets[i].items) {
          candidate.add(item);
        }

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

    for (FrequentItemset itemset in itemsets) {
      if (itemset.items.length < 2) {
        continue;
      }

      for (String consequent in itemset.items) {
        List<String> antecedents = [];
        for (String item in itemset.items) {
          if (item != consequent) {
            antecedents.add(item);
          }
        }

        if (antecedents.isEmpty) {
          continue;
        }

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

        double confidence = itemset.support / (antCount / total);

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

  String getActionText() {
    if (action == ModerationAction.approved) {
      return 'APPROVED';
    } else if (action == ModerationAction.flagged) {
      return 'FLAGGED';
    } else {
      return 'BLOCKED';
    }
  }
}
