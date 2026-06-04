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
    final Map<String, double> activeBalances = Map.from(balances);
    final List<String> sortedCreditors = creditors.map((e) => e.key).toList();
    final List<String> sortedDebtors = debtors.map((e) => e.key).toList();
    final List<Settlement> settlements = [];
    
    int debtorIndex = 0;
    int creditorIndex = 0;

    while (debtorIndex < sortedDebtors.length && creditorIndex < sortedCreditors.length) {
      final String debtorKey = sortedDebtors[debtorIndex];
      final String creditorKey = sortedCreditors[creditorIndex];
      
      final double debtorAmount = -activeBalances[debtorKey]!;
      final double creditorAmount = activeBalances[creditorKey]!;
      
      // Skip settled members to handle precision variations
      if (debtorAmount <= 0.001) {
        debtorIndex++;
        continue;
      }
      if (creditorAmount <= 0.001) {
        creditorIndex++;
        continue;
      }
      
      final double amount = debtorAmount < creditorAmount 
          ? debtorAmount 
          : creditorAmount;
      
      settlements.add(Settlement(
        fromMember: debtorKey,
        toMember: creditorKey,
        amount: amount,
      ));
      
      // Update running balances
      activeBalances[debtorKey] = -(debtorAmount - amount);
      activeBalances[creditorKey] = creditorAmount - amount;
      
      if (debtorAmount < creditorAmount) {
        debtorIndex++;
      } else if (debtorAmount > creditorAmount) {
        creditorIndex++;
      } else {
        debtorIndex++;
        creditorIndex++;
      }
    }

    return settlements;
  }
}
