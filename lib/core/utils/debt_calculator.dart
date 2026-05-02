class Member {
  final String name;
  final double totalPaid;
  final double totalShare;

  Member({
    required this.name,
    required this.totalPaid,
    required this.totalShare,
  });

  double get balance => totalPaid - totalShare;
}

class Settlement {
  final String fromMember;
  final String toMember;
  final double amount;
  bool isPaid;

  Settlement({
    required this.fromMember,
    required this.toMember,
    required this.amount,
    this.isPaid = false,
  });
}

class DebtCalculator {
  static List<Settlement> calculate(List<Member> members) {
    // 1. Calculate net balance per member
    final Map<String, double> balances = {};
    for (final member in members) {
      balances[member.name] = member.balance;
    }

    // 2. Separate into creditors (positive) and debtors (negative)
    final List<MapEntry<String, double>> creditors = [];
    final List<MapEntry<String, double>> debtors = [];

    for (final entry in balances.entries) {
      if (entry.value > 0) {
        creditors.add(entry);
      } else if (entry.value < 0) {
        debtors.add(entry);
      }
    }

    // 3. Sort by amount (largest first)
    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => a.value.compareTo(b.value));

    // 4. Greedy algorithm to find minimum transactions
    final List<Settlement> settlements = [];
    int debtorIndex = 0;
    int creditorIndex = 0;

    while (debtorIndex < debtors.length && creditorIndex < creditors.length) {
      final debtor = debtors[debtorIndex];
      final creditor = creditors[creditorIndex];
      
      final double debtorAmount = -debtor.value; // Convert to positive
      final double creditorAmount = creditor.value;
      
      final double amount = debtorAmount < creditorAmount 
          ? debtorAmount 
          : creditorAmount;
      
      settlements.add(Settlement(
        fromMember: debtor.key,
        toMember: creditor.key,
        amount: amount,
      ));
      
      // Update balances
      if (debtorAmount < creditorAmount) {
        // Debtor is fully settled, creditor has remaining
        balances[creditor.key] = creditorAmount - amount;
        debtorIndex++;
      } else if (debtorAmount > creditorAmount) {
        // Creditor is fully settled, debtor has remaining
        balances[debtor.key] = -(debtorAmount - amount);
        creditorIndex++;
      } else {
        // Both are fully settled
        debtorIndex++;
        creditorIndex++;
      }
    }

    return settlements;
  }
}
