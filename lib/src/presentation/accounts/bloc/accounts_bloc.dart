import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart' show immutable;
import 'package:paisa/src/core/common.dart';
import 'package:paisa/src/data/currencies/models/currency_model.dart';

import '../../../core/enum/card_type.dart';
import '../../../data/category/model/category_model.dart';
import '../../../domain/account/entities/account.dart';
import '../../../domain/account/use_case/account_use_case.dart';
import '../../../domain/category/use_case/category_use_case.dart';
import '../../../domain/expense/entities/expense.dart';
import '../../../domain/expense/use_case/expense_use_case.dart';

part 'accounts_event.dart';
part 'accounts_state.dart';

@injectable
class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  AccountsBloc({
    required this.getAccountUseCase,
    required this.deleteAccountUseCase,
    required this.getExpensesFromAccountIdUseCase,
    required this.addAccountUseCase,
    required this.getAccountsUseCase,
    required this.getCategoryUseCase,
    required this.deleteExpensesFromAccountIdUseCase,
    required this.updateAccountUseCase,
    //required this.getCurrencyUseCase,
  }) : super(AccountsInitial()) {
    on<AccountsEvent>((event, emit) {});
    on<AddOrUpdateAccountEvent>(_addAccount);
    on<DeleteAccountEvent>(_deleteAccount);
    on<AccountSelectedEvent>(_accountSelected);
    on<UpdateCardTypeEvent>(_updateCardType);
    on<FetchAccountFromIdEvent>(_fetchAccountFromId);
  }

  final GetExpensesFromAccountIdUseCase getExpensesFromAccountIdUseCase;
  final DeleteExpensesFromAccountIdUseCase deleteExpensesFromAccountIdUseCase;
  final UpdateAccountUseCase updateAccountUseCase;
  final GetAccountUseCase getAccountUseCase;
  final DeleteAccountUseCase deleteAccountUseCase;
  final AddAccountUseCase addAccountUseCase;
  final GetAccountsUseCase getAccountsUseCase;
  final GetCategoryUseCase getCategoryUseCase;

  CardType selectedType = CardType.cash;
  String? accountName;
  String? accountHolderName;
  String? accountNumber;
  Account? currentAccount;
  double? initialAmount;
  String? currency;

  Future<void> _fetchAccountFromId(
      FetchAccountFromIdEvent event,
      Emitter<AccountsState> emit,
      ) async {
    final int? accountId = int.tryParse(event.accountId ?? '');
    if (accountId == null) return;

    final Account? account = getAccountUseCase(accountId);
    if (account != null) {
      accountName = account.bankName;
      accountHolderName = account.name;
      accountNumber = account.number;
      selectedType = account.cardType ?? CardType.cash;
      initialAmount = account.amount;
      currency = account.currency;
      currentAccount = account;
      emit(AccountSuccessState(account));
      emit(UpdateCardTypeState(selectedType));
    } else {
      emit(const AccountErrorState('Account not found!'));
    }
  }

  Future<void> _addAccount(
      AddOrUpdateAccountEvent event,
      Emitter<AccountsState> emit,
      ) async {
    final String? bankName = accountName;
    final String? holderName = accountHolderName;
    final String? number = accountNumber;
    final CardType cardType = selectedType;
    final double? amount = initialAmount;
    final String? currency = this.currency;

    if (bankName == null) {
      return emit(const AccountErrorState('Set bank name'));
    }
    if (holderName == null) {
      return emit(const AccountErrorState('Set account holder name'));
    }

    if (event.isAdding) {
      await addAccountUseCase(
        bankName: bankName,
        holderName: holderName,
        number: number ?? '',
        currency: currency ?? 'USD',
        cardType: cardType,
        amount: amount ?? 0,
      );
    } else {
      if (currentAccount != null) {
        currentAccount!
          ..bankName = bankName
          ..cardType = cardType
          ..icon = cardType.icon.codePoint
          ..name = holderName
          ..number = number ?? ''
          ..amount = amount
          ..currency = currency ?? 'USD';

        await updateAccountUseCase(account: currentAccount!);
      }
    }
    emit(AddAccountState(isAddOrUpdate: event.isAdding));
  }

  FutureOr<void> _deleteAccount(
      DeleteAccountEvent event,
      Emitter<AccountsState> emit,
      ) async {
    await deleteExpensesFromAccountIdUseCase(event.accountId);
    await deleteAccountUseCase(event.accountId);
    emit(AccountDeletedState());
  }

  FutureOr<void> _accountSelected(
      AccountSelectedEvent event,
      Emitter<AccountsState> emit,
      ) async =>
      emit(AccountSelectedState(event.account));

  FutureOr<void> _updateCardType(
      UpdateCardTypeEvent event,
      Emitter<AccountsState> emit,
      ) async {
    selectedType = event.cardType;
    emit(UpdateCardTypeState(event.cardType));
  }

  FutureOr<void> _updateCurrency(
      UpdateCurrencyEvent event,
      Emitter<AccountsState> emit,
      ) async {
    currency = event.currency;
    emit(UpdateCurrencyState(event.currency));
  }



  CategoryModel? fetchCategoryFromId(int categoryId) =>
      getCategoryUseCase(categoryId);

  List<Expense> fetchExpenseFromAccountId(int accountId) =>
      getExpensesFromAccountIdUseCase(accountId);
}
