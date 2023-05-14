import 'dart:math';

import 'package:flutter/material.dart';
import 'package:paisa/main.dart';
import 'package:paisa/src/core/enum/card_type.dart';
import 'package:paisa/src/core/enum/transaction_type.dart';
import 'package:paisa/src/domain/account/repository/account_repository.dart';
import 'package:paisa/src/domain/category/repository/category_repository.dart';
import 'package:paisa/src/domain/expense/repository/expense_repository.dart';

// Generate dummy data
Future<void> addDummyData() async {
  final AccountRepository accRepo = getIt.get();
  final CategoryRepository catRepo = getIt.get();
  final ExpenseRepository expRepo = getIt.get();
  final ints = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
  for (var index in ints) {
    await accRepo.addAccount(
      bankName: 'Bank Name $index',
      holderName: 'Holder Name $index',
      number: '$index',
      cardType: CardType.bank,
      amount: 0,
      currency: 'PLN',
    );
    await catRepo.addCategory(
      name: 'Category Name $index',
      icon: Icons.abc.codePoint,
      color: Colors.amber.value,
    );
    for (var i = 0; i < 20; i++) {
      await expRepo.addExpense(
        'Name $index',
        Random().nextDouble() * 100000,
        DateTime.now().add(Duration(days: Random().nextInt(100))),
        index,
        index,
        Random().nextBool() ? TransactionType.expense : TransactionType.income,
        'description',
        null,
        null,
        0,
      );
    }
  }
}
