import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isDuplicateEntity matches postgres unique violation text', () {
    const e = ApiException(
      message: 'HTTP 422',
      statusCode: 422,
      body: {
        'errors': [
          'PG::UniqueViolation: ERROR: duplicate key value violates unique constraint '
              '"videos_pkey"\nDETAIL: Key (id)=(5fb39bd1-8b7b-5fda-9d5f-8850dfca1042) already exists.',
        ],
      },
    );

    expect(e.isDuplicateEntity, isTrue);
  });

  test('isDuplicateEntity ignores unrelated client errors', () {
    const e = ApiException(
      message: 'HTTP 422',
      statusCode: 422,
      body: {
        'errors': ['title cannot be blank'],
      },
    );

    expect(e.isDuplicateEntity, isFalse);
  });
}
