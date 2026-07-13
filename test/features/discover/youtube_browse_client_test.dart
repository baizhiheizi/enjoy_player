import 'dart:convert';

import 'package:enjoy_player/features/discover/data/youtube_browse_client.dart';
import 'package:enjoy_player/features/transcript/data/client_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _webProfile = ClientProfile(
  name: 'web',
  clientName: 'WEB',
  clientVersion: '2.20240101.00.00',
  clientNameHeader: '1',
  userAgent:
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
  context: {'platform': 'DESKTOP', 'osName': 'Windows', 'osVersion': '10.0'},
);

const _mwebProfile = ClientProfile(
  name: 'mweb',
  clientName: 'MWEB',
  clientVersion: '2.20251209.01.00',
  clientNameHeader: '2',
  userAgent:
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
  context: {'platform': 'MOBILE', 'osName': 'iOS', 'osVersion': '17.5.1'},
);

/// Build a single InnerTube `videoRenderer` JSON fragment.
Map<String, dynamic> _videoRenderer({
  required String videoId,
  String title = 'Title',
  String? thumbnail,
  String? lengthText,
  String? publishedTimeText,
  String? viewCountText,
}) {
  final v = <String, dynamic>{
    'videoId': videoId,
    'title': {
      'runs': [
        {'text': title},
      ],
    },
  };
  if (thumbnail != null) {
    v['thumbnail'] = {
      'thumbnails': [
        {'url': thumbnail},
      ],
    };
  }
  if (lengthText != null) {
    v['lengthText'] = {'simpleText': lengthText};
  }
  if (publishedTimeText != null) {
    v['publishedTimeText'] = {'simpleText': publishedTimeText};
  }
  if (viewCountText != null) {
    v['viewCountText'] = {'simpleText': viewCountText};
  }
  return {
    'richItemRenderer': {
      'content': {'videoRenderer': v},
    },
  };
}

Map<String, dynamic> _continuationItem(String token) => {
  'continuationItemRenderer': {
    'continuationEndpoint': {
      'continuationCommand': {'token': token},
    },
  },
};

/// Wrap a list of `richGridRenderer.contents` into a full InnerTube browse
/// response. Pass `[]` for an empty page.
Map<String, dynamic> _browseResponse(List<Map<String, dynamic>> contents) => {
  'contents': {
    'twoColumnBrowseResultsRenderer': {
      'tabs': [
        {
          'tabRenderer': {
            'content': {
              'richGridRenderer': {'contents': contents},
            },
          },
        },
      ],
    },
  },
};

void main() {
  group('YoutubeBrowseClient', () {
    test(
      'browse client: parses one-page InnerTube response into BrowseVideoEntry list',
      () async {
        final body = _browseResponse([
          _videoRenderer(
            videoId: 'videoA0000001',
            title: 'First',
            thumbnail: 'https://i.ytimg.com/vi/videoA0000001/hqdefault.jpg',
            lengthText: '12:34',
            publishedTimeText: '3 days ago',
            viewCountText: '1.2K views',
          ),
          _videoRenderer(
            videoId: 'videoB0000002',
            title: 'Second',
            thumbnail: 'https://i.ytimg.com/vi/videoB0000002/hqdefault.jpg',
            lengthText: '1:02:03',
            publishedTimeText: '1 hour ago',
          ),
          _videoRenderer(
            videoId: 'videoC0000003',
            title: 'Third',
            publishedTimeText: '2 weeks ago',
          ),
        ]);

        final client = YoutubeBrowseClient(
          client: MockClient((req) async {
            return http.Response(jsonEncode(body), 200);
          }),
          profiles: [_webProfile],
        );

        final fetchedAt = DateTime.utc(2024, 6, 1);
        final outcome = await client.fetchChannelVideos(
          channelId: 'UCtestchannel1',
          fetchedAt: fetchedAt,
        );

        expect(outcome.entries, hasLength(3));
        expect(outcome.pagesFetched, 1);
        expect(outcome.exhaustedPages, isFalse);
        expect(outcome.profileUsed, 'web');

        final first = outcome.entries[0];
        expect(first.videoId, 'videoA0000001');
        expect(first.title, 'First');
        expect(
          first.thumbnailUrl,
          'https://i.ytimg.com/vi/videoA0000001/hqdefault.jpg',
        );
        expect(first.durationSeconds, 754); // 12:34
        expect(first.viewCountText, '1.2K views');
        expect(first.publishedAt, DateTime.utc(2024, 5, 29)); // 3 days before
        expect(first.nextPageToken, isNull);

        final second = outcome.entries[1];
        expect(second.durationSeconds, 3723); // 1:02:03

        final third = outcome.entries[2];
        expect(third.durationSeconds, isNull);
        expect(third.viewCountText, isNull);
        expect(third.thumbnailUrl, isNull);
      },
    );

    test('browse client: follows continuation token across 3 pages', () async {
      var pageIndex = 0;
      final client = YoutubeBrowseClient(
        client: MockClient((req) async {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          final isInitial = body.containsKey('browseId');
          expect(isInitial || body.containsKey('continuation'), isTrue);

          pageIndex += 1;
          if (pageIndex == 1) {
            return http.Response(
              jsonEncode(
                _browseResponse([
                  for (var i = 0; i < 30; i++)
                    _videoRenderer(
                      videoId: 'p1v${i.toString().padLeft(9, '0')}',
                      publishedTimeText: '${i + 1} hours ago',
                    ),
                  _continuationItem('TOKEN_PAGE_2'),
                ]),
              ),
              200,
            );
          }
          if (pageIndex == 2) {
            return http.Response(
              jsonEncode(
                _browseResponse([
                  for (var i = 0; i < 30; i++)
                    _videoRenderer(
                      videoId: 'p2v${i.toString().padLeft(9, '0')}',
                      publishedTimeText: '${i + 1} hours ago',
                    ),
                  _continuationItem('TOKEN_PAGE_3'),
                ]),
              ),
              200,
            );
          }
          // page 3 — empty, no continuation
          return http.Response(jsonEncode(_browseResponse([])), 200);
        }),
        profiles: [_webProfile],
      );

      final fetchedAt = DateTime.utc(2024, 6, 1);
      final outcome = await client.fetchChannelVideos(
        channelId: 'UCtestchannel2',
        fetchedAt: fetchedAt,
      );

      expect(outcome.entries, hasLength(60));
      expect(outcome.pagesFetched, 3);
      expect(outcome.exhaustedPages, isFalse);
      // 30 + 30 unique ids
      final ids = outcome.entries.map((e) => e.videoId).toSet();
      expect(ids.length, 60);
    });

    test(
      'browse client: honors `maxPages` and reports `exhaustedPages`',
      () async {
        var pageIndex = 0;
        final client = YoutubeBrowseClient(
          client: MockClient((req) async {
            pageIndex += 1;
            // Every page has a continuation token; the client must stop at maxPages.
            return http.Response(
              jsonEncode(
                _browseResponse([
                  for (var i = 0; i < 30; i++)
                    _videoRenderer(
                      videoId: 'p${pageIndex}v${i.toString().padLeft(8, '0')}',
                      publishedTimeText: '${i + 1} hours ago',
                    ),
                  _continuationItem('TOKEN_PAGE_${pageIndex + 1}'),
                ]),
              ),
              200,
            );
          }),
          profiles: [_webProfile],
          maxPages: 5,
        );

        final fetchedAt = DateTime.utc(2024, 6, 1);
        final outcome = await client.fetchChannelVideos(
          channelId: 'UCtestchannel3',
          fetchedAt: fetchedAt,
        );

        expect(outcome.entries, hasLength(150));
        expect(outcome.pagesFetched, 5);
        expect(outcome.exhaustedPages, isTrue);
      },
    );

    test(
      'browse client: empty response returns empty list without throwing',
      () async {
        final client = YoutubeBrowseClient(
          client: MockClient((req) async {
            return http.Response(jsonEncode(_browseResponse([])), 200);
          }),
          profiles: [_webProfile],
        );

        final outcome = await client.fetchChannelVideos(
          channelId: 'UCtestchannel4',
          fetchedAt: DateTime.utc(2024, 6, 1),
        );

        expect(outcome.entries, isEmpty);
        expect(outcome.pagesFetched, 1);
        expect(outcome.exhaustedPages, isFalse);
        expect(outcome.profileUsed, 'web');
      },
    );

    test(
      'browse client: missing richGridRenderer throws YoutubeBrowseException',
      () async {
        final client = YoutubeBrowseClient(
          client: MockClient((req) async {
            return http.Response(
              jsonEncode({
                'contents': {
                  'twoColumnBrowseResultsRenderer': {
                    'tabs': [
                      {
                        'tabRenderer': {
                          'content': {
                            'sectionListRenderer': {'contents': []},
                          },
                        },
                      },
                    ],
                  },
                },
              }),
              200,
            );
          }),
          profiles: [_webProfile],
        );

        await expectLater(
          client.fetchChannelVideos(
            channelId: 'UCtestchannel5',
            fetchedAt: DateTime.utc(2024, 6, 1),
          ),
          throwsA(
            isA<YoutubeBrowseException>().having(
              (e) => e.message,
              'message',
              contains('no recognisable videoRenderers'),
            ),
          ),
        );
      },
    );

    test(
      'browse client: per-profile retry on 401 — retries next profile before throwing',
      () async {
        var webCalls = 0;
        var mwebCalls = 0;
        final client = YoutubeBrowseClient(
          client: MockClient((req) async {
            final body = jsonDecode(req.body) as Map<String, dynamic>;
            final clientName =
                (body['context'] as Map<String, dynamic>)['client']
                    as Map<String, dynamic>;
            final name = clientName['clientName'] as String;
            if (name == 'WEB') {
              webCalls += 1;
              return http.Response('', 401);
            }
            if (name == 'MWEB') {
              mwebCalls += 1;
              return http.Response(
                jsonEncode(
                  _browseResponse([
                    _videoRenderer(
                      videoId: 'fallback00000001',
                      publishedTimeText: '1 hour ago',
                    ),
                  ]),
                ),
                200,
              );
            }
            return http.Response('', 404);
          }),
          profiles: [_webProfile, _mwebProfile],
        );

        final outcome = await client.fetchChannelVideos(
          channelId: 'UCtestchannel6',
          fetchedAt: DateTime.utc(2024, 6, 1),
        );

        expect(webCalls, 1);
        expect(mwebCalls, 1);
        expect(outcome.entries, hasLength(1));
        expect(outcome.entries.first.videoId, 'fallback00000001');
        expect(outcome.profileUsed, 'mweb');
      },
    );

    test(
      'browse client: all profiles 401 throws YoutubeBrowseException',
      () async {
        final client = YoutubeBrowseClient(
          client: MockClient((req) async {
            return http.Response('', 401);
          }),
          profiles: [_webProfile, _mwebProfile],
        );

        await expectLater(
          client.fetchChannelVideos(
            channelId: 'UCtestchannel7',
            fetchedAt: DateTime.utc(2024, 6, 1),
          ),
          throwsA(
            isA<YoutubeBrowseException>().having(
              (e) => e.statusCode,
              'statusCode',
              401,
            ),
          ),
        );
      },
    );

    group('parsing helpers', () {
      test('parseInnerTubeLengthText handles standard forms', () {
        expect(parseInnerTubeLengthText('1:23'), 83);
        expect(parseInnerTubeLengthText('12:34'), 754);
        expect(parseInnerTubeLengthText('1:02:03'), 3723);
        expect(parseInnerTubeLengthText('42'), 42);
        expect(parseInnerTubeLengthText('0:00'), isNull);
        expect(parseInnerTubeLengthText(''), isNull);
        expect(parseInnerTubeLengthText('abc'), isNull);
        expect(parseInnerTubeLengthText('1:2:3:4'), isNull);
      });

      test('parseInnerTubePublishedTimeText handles common shapes', () {
        final fetchedAt = DateTime.utc(2024, 6, 1);
        expect(
          parseInnerTubePublishedTimeText('3 days ago', fetchedAt),
          fetchedAt.subtract(const Duration(days: 3)),
        );
        expect(
          parseInnerTubePublishedTimeText('1 hour ago', fetchedAt),
          fetchedAt.subtract(const Duration(hours: 1)),
        );
        expect(
          parseInnerTubePublishedTimeText('30 minutes ago', fetchedAt),
          fetchedAt.subtract(const Duration(minutes: 30)),
        );
        expect(
          parseInnerTubePublishedTimeText('2 weeks ago', fetchedAt),
          fetchedAt.subtract(const Duration(days: 14)),
        );
        expect(
          parseInnerTubePublishedTimeText('5 months ago', fetchedAt),
          fetchedAt.subtract(const Duration(days: 150)),
        );
        expect(
          parseInnerTubePublishedTimeText('1 year ago', fetchedAt),
          fetchedAt.subtract(const Duration(days: 365)),
        );
        expect(
          parseInnerTubePublishedTimeText(
            'Streamed live 2 days ago',
            fetchedAt,
          ),
          fetchedAt.subtract(const Duration(days: 2)),
        );
        expect(
          parseInnerTubePublishedTimeText('Premiered 5 months ago', fetchedAt),
          fetchedAt.subtract(const Duration(days: 150)),
        );
        // Defensive fallback for unknown shapes.
        expect(
          parseInnerTubePublishedTimeText('unknown shape', fetchedAt),
          fetchedAt,
        );
      });
    });

    test('browse client: shelfRenderer fallback extracts gridVideoRenderer items '
        '(TED-style response without richGridRenderer)', () async {
      final body = {
        'contents': {
          'twoColumnBrowseResultsRenderer': {
            'tabs': [
              {
                'tabRenderer': {
                  'content': {
                    'sectionListRenderer': {
                      'contents': [
                        {
                          'itemSectionRenderer': {
                            'contents': [
                              {
                                'shelfRenderer': {
                                  'title': 'Videos',
                                  'content': {
                                    'horizontalListRenderer': {
                                      'items': [
                                        {
                                          'gridVideoRenderer': {
                                            'videoId': 'shelfV00000001',
                                            'title': {
                                              'runs': [
                                                {'text': 'Shelf Video 1'},
                                              ],
                                            },
                                            'thumbnail': {
                                              'thumbnails': [
                                                {
                                                  'url':
                                                      'https://i.ytimg.com/vi/shelfV00000001/hqdefault.jpg',
                                                },
                                              ],
                                            },
                                            'thumbnailOverlays': [
                                              {
                                                'thumbnailOverlayTimeStatusRenderer':
                                                    {
                                                      'text': {
                                                        'simpleText': '5:43',
                                                      },
                                                    },
                                              },
                                            ],
                                            'publishedTimeText': {
                                              'simpleText': '1 week ago',
                                            },
                                            'viewCountText': {
                                              'simpleText': '42K views',
                                            },
                                          },
                                        },
                                        {
                                          'gridVideoRenderer': {
                                            'videoId': 'shelfV00000002',
                                            'title': {
                                              'simpleText': 'Shelf Video 2',
                                            },
                                            'publishedTimeText': {
                                              'simpleText': '2 weeks ago',
                                            },
                                          },
                                        },
                                      ],
                                    },
                                  },
                                },
                              },
                            ],
                          },
                        },
                      ],
                    },
                  },
                },
              },
            ],
          },
        },
      };

      final client = YoutubeBrowseClient(
        client: MockClient((req) async {
          return http.Response(jsonEncode(body), 200);
        }),
        profiles: [_webProfile],
      );

      final outcome = await client.fetchChannelVideos(
        channelId: 'UCtestshelf01',
        fetchedAt: DateTime.utc(2024, 6, 1),
      );

      expect(outcome.entries, hasLength(2));
      expect(outcome.entries[0].videoId, 'shelfV00000001');
      expect(outcome.entries[0].title, 'Shelf Video 1');
      expect(outcome.entries[0].durationSeconds, 343); // 5:43
      expect(outcome.entries[0].viewCountText, '42K views');
      expect(
        outcome.entries[0].thumbnailUrl,
        'https://i.ytimg.com/vi/shelfV00000001/hqdefault.jpg',
      );
      expect(outcome.entries[1].videoId, 'shelfV00000002');
      // No continuation token — shelfRenderer path is not paginated.
      expect(outcome.pagesFetched, 1);
      expect(outcome.exhaustedPages, isFalse);
    });

    test(
      'browse client: deep-search fallback extracts videoRenderer '
      'when no richGridRenderer and no sectionListRenderer present',
      () async {
        // Simulates a response with an unusual top-level wrapper (e.g. an
        // appendContinuationItemsAction or a minimal single-video response).
        final body = {
          'contents': {
            'twoColumnBrowseResultsRenderer': {
              'tabs': [
                {
                  'tabRenderer': {
                    'content': {
                      'unusualRenderer': {
                        'items': [
                          {
                            'richItemRenderer': {
                              'content': {
                                'videoRenderer': {
                                  'videoId': 'deepV000000001',
                                  'title': {
                                    'runs': [
                                      {'text': 'Deep 1'},
                                    ],
                                  },
                                  'publishedTimeText': {
                                    'simpleText': '3 days ago',
                                  },
                                },
                              },
                            },
                          },
                          {
                            'richItemRenderer': {
                              'content': {
                                'videoRenderer': {
                                  'videoId': 'deepV000000002',
                                  'title': {
                                    'runs': [
                                      {'text': 'Deep 2'},
                                    ],
                                  },
                                  'publishedTimeText': {
                                    'simpleText': '1 hour ago',
                                  },
                                },
                              },
                            },
                          },
                        ],
                      },
                    },
                  },
                },
              ],
            },
          },
        };

        final client = YoutubeBrowseClient(
          client: MockClient((req) async {
            return http.Response(jsonEncode(body), 200);
          }),
          profiles: [_webProfile],
        );

        final outcome = await client.fetchChannelVideos(
          channelId: 'UCtestdeep01',
          fetchedAt: DateTime.utc(2024, 6, 1),
        );

        expect(outcome.entries, hasLength(2));
        final ids = outcome.entries.map((e) => e.videoId).toSet();
        expect(ids, containsAll(['deepV000000001', 'deepV000000002']));
        expect(outcome.pagesFetched, 1);
      },
    );

    test(
      'browse client: deep-search fallback dedupes across renderer paths',
      () async {
        // The same videoId appears under both a richGridRenderer item AND a
        // shelfRenderer item. The deep-search path should not double-count it.
        final body = {
          'contents': {
            'twoColumnBrowseResultsRenderer': {
              'tabs': [
                {
                  'tabRenderer': {
                    'content': {
                      // First tab: empty sectionList (no entries here).
                      'sectionListRenderer': {'contents': []},
                    },
                  },
                },
                {
                  'tabRenderer': {
                    'content': {
                      // Second tab: a shelf containing two videos.
                      'sectionListRenderer': {
                        'contents': [
                          {
                            'itemSectionRenderer': {
                              'contents': [
                                {
                                  'shelfRenderer': {
                                    'content': {
                                      'horizontalListRenderer': {
                                        'items': [
                                          {
                                            'gridVideoRenderer': {
                                              'videoId': 'dupVid00000001',
                                              'title': {
                                                'runs': [
                                                  {'text': 'Duplicate 1'},
                                                ],
                                              },
                                              'publishedTimeText': {
                                                'simpleText': '1 day ago',
                                              },
                                            },
                                          },
                                          {
                                            'gridVideoRenderer': {
                                              'videoId': 'shelfOnly00001',
                                              'title': {
                                                'runs': [
                                                  {'text': 'Shelf Only'},
                                                ],
                                              },
                                              'publishedTimeText': {
                                                'simpleText': '2 days ago',
                                              },
                                            },
                                          },
                                        ],
                                      },
                                    },
                                  },
                                },
                              ],
                            },
                          },
                        ],
                      },
                    },
                  },
                },
              ],
            },
          },
        };

        final client = YoutubeBrowseClient(
          client: MockClient((req) async {
            return http.Response(jsonEncode(body), 200);
          }),
          profiles: [_webProfile],
        );

        final outcome = await client.fetchChannelVideos(
          channelId: 'UCtestdedupe01',
          fetchedAt: DateTime.utc(2024, 6, 1),
        );

        // The shelf path returns 2 entries (no continuation), deep search is
        // not reached. If the shelf path were skipped (e.g., empty), the deep
        // search would find the same videos again and dedupe to the same set.
        final ids = outcome.entries.map((e) => e.videoId).toList();
        expect(ids.toSet(), hasLength(2));
        expect(ids, containsAll(['dupVid00000001', 'shelfOnly00001']));
      },
    );

    test('browse client: richGridRenderer path takes precedence over shelf and '
        'deep search when present', () async {
      // Response has BOTH a richGridRenderer AND a shelfRenderer with the
      // same videoIds. The richGridRenderer path should win.
      final body = {
        'contents': {
          'twoColumnBrowseResultsRenderer': {
            'tabs': [
              {
                'tabRenderer': {
                  'content': {
                    'richGridRenderer': {
                      'contents': [
                        {
                          'richItemRenderer': {
                            'content': {
                              'videoRenderer': {
                                'videoId': 'gridVid0000001',
                                'title': {
                                  'runs': [
                                    {'text': 'Grid'},
                                  ],
                                },
                                'publishedTimeText': {
                                  'simpleText': '1 hour ago',
                                },
                              },
                            },
                          },
                        },
                        {
                          'continuationItemRenderer': {
                            'continuationEndpoint': {
                              'continuationCommand': {'token': 'CONT'},
                            },
                          },
                        },
                      ],
                    },
                    'sectionListRenderer': {
                      'contents': [
                        {
                          'itemSectionRenderer': {
                            'contents': [
                              {
                                'shelfRenderer': {
                                  'content': {
                                    'horizontalListRenderer': {
                                      'items': [
                                        {
                                          'gridVideoRenderer': {
                                            'videoId': 'shelfVid00001',
                                            'title': {
                                              'runs': [
                                                {'text': 'Shelf'},
                                              ],
                                            },
                                            'publishedTimeText': {
                                              'simpleText': '1 day ago',
                                            },
                                          },
                                        },
                                      ],
                                    },
                                  },
                                },
                              },
                            ],
                          },
                        },
                      ],
                    },
                  },
                },
              },
            ],
          },
        },
      };

      final client = YoutubeBrowseClient(
        client: MockClient((req) async {
          // Continuation calls return an empty grid so the pagination
          // loop terminates after the first page.
          final reqBody = jsonDecode(req.body) as Map<String, dynamic>;
          if (reqBody.containsKey('continuation')) {
            return http.Response(
              jsonEncode({
                'contents': {
                  'twoColumnBrowseResultsRenderer': {
                    'tabs': [
                      {
                        'tabRenderer': {
                          'content': {
                            'richGridRenderer': {'contents': []},
                          },
                        },
                      },
                    ],
                  },
                },
              }),
              200,
            );
          }
          return http.Response(jsonEncode(body), 200);
        }),
        profiles: [_webProfile],
      );

      final outcome = await client.fetchChannelVideos(
        channelId: 'UCtestprefer01',
        fetchedAt: DateTime.utc(2024, 6, 1),
      );

      // Only the richGridRenderer entry is returned; the shelf entry is
      // ignored. The continuation token is captured and the empty
      // continuation response terminates the loop after 2 pages.
      expect(outcome.entries, hasLength(1));
      expect(outcome.entries.single.videoId, 'gridVid0000001');
      expect(outcome.pagesFetched, 2);
    });

    test('browse client: parses richGridRenderer items wrapped in '
        'richItemRenderer.content.lockupViewModel (TED-style response)', () async {
      // TED's browse response wraps each video in a lockupViewModel node
      // (the 2024+ InnerTube renderer family). The metadata is split across
      // contentImage (thumbnail + duration overlay) and metadata
      // (lockupMetadataViewModel -> title, contentMetadataViewModel for
      // published time / view count).
      final body = {
        'contents': {
          'twoColumnBrowseResultsRenderer': {
            'tabs': [
              {
                'tabRenderer': {
                  'content': {
                    'richGridRenderer': {
                      'contents': [
                        {
                          'richItemRenderer': {
                            'content': {
                              'lockupViewModel': {
                                'contentId': 'lockupVid000001',
                                'contentType': 'LOCKUP_CONTENT_TYPE_VIDEO',
                                'contentImage': {
                                  'thumbnailViewModel': {
                                    'image': {
                                      'sources': [
                                        {
                                          'url':
                                              'https://i.ytimg.com/vi/lockupVid000001/hqdefault.jpg',
                                        },
                                      ],
                                    },
                                    'overlays': [
                                      {
                                        'thumbnailOverlayBadgeViewModel': {
                                          'thumbnailBadges': [
                                            {
                                              'thumbnailBadgeViewModel': {
                                                'text': '12:34',
                                              },
                                            },
                                          ],
                                        },
                                      },
                                    ],
                                  },
                                },
                                'metadata': {
                                  'lockupMetadataViewModel': {
                                    'title': {'content': 'Lockup Title 1'},
                                    'metadata': {
                                      'contentMetadataViewModel': {
                                        'metadataRows': [
                                          {
                                            'metadataParts': [
                                              {
                                                'text': {
                                                  'content': '12K views',
                                                },
                                              },
                                            ],
                                          },
                                          {
                                            'metadataParts': [
                                              {
                                                'text': {
                                                  'content': '3 days ago',
                                                },
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                        {
                          'richItemRenderer': {
                            'content': {
                              'lockupViewModel': {
                                'contentId': 'lockupVid000002',
                                'contentType': 'LOCKUP_CONTENT_TYPE_VIDEO',
                                'contentImage': {
                                  'thumbnailViewModel': {
                                    'overlays': [
                                      {
                                        'thumbnailBottomOverlayViewModel': {
                                          'badges': [
                                            {
                                              'thumbnailBadgeViewModel': {
                                                'text': '5:43',
                                              },
                                            },
                                          ],
                                        },
                                      },
                                    ],
                                  },
                                },
                                'metadata': {
                                  'lockupMetadataViewModel': {
                                    'title': {'content': 'Lockup Title 2'},
                                    'metadata': {
                                      'contentMetadataViewModel': {
                                        'metadataRows': [
                                          {
                                            'metadataParts': [
                                              {
                                                'text': {
                                                  'content':
                                                      'Streamed live 2 days ago',
                                                },
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                        {
                          'continuationItemRenderer': {
                            'continuationEndpoint': {
                              'continuationCommand': {'token': 'CONT_TOKEN'},
                            },
                          },
                        },
                      ],
                    },
                  },
                },
              },
            ],
          },
        },
      };

      final client = YoutubeBrowseClient(
        client: MockClient((req) async {
          // Continuation calls return an empty grid so pagination
          // terminates after the first page.
          final reqBody = jsonDecode(req.body) as Map<String, dynamic>;
          if (reqBody.containsKey('continuation')) {
            return http.Response(
              jsonEncode({
                'contents': {
                  'twoColumnBrowseResultsRenderer': {
                    'tabs': [
                      {
                        'tabRenderer': {
                          'content': {
                            'richGridRenderer': {'contents': []},
                          },
                        },
                      },
                    ],
                  },
                },
              }),
              200,
            );
          }
          return http.Response(jsonEncode(body), 200);
        }),
        profiles: [_webProfile],
      );

      final outcome = await client.fetchChannelVideos(
        channelId: 'UCtestlockup01',
        fetchedAt: DateTime.utc(2024, 6, 1),
      );

      expect(outcome.entries, hasLength(2));

      final first = outcome.entries[0];
      expect(first.videoId, 'lockupVid000001');
      expect(first.title, 'Lockup Title 1');
      expect(
        first.thumbnailUrl,
        'https://i.ytimg.com/vi/lockupVid000001/hqdefault.jpg',
      );
      expect(first.durationSeconds, 754); // 12:34
      expect(
        first.publishedAt,
        DateTime.utc(2024, 6, 1).subtract(const Duration(days: 3)),
      );

      final second = outcome.entries[1];
      expect(second.videoId, 'lockupVid000002');
      expect(second.title, 'Lockup Title 2');
      expect(second.thumbnailUrl, isNull); // No sources in this fixture.
      expect(second.durationSeconds, 343); // 5:43
      expect(
        second.publishedAt,
        DateTime.utc(2024, 6, 1).subtract(const Duration(days: 2)),
      );

      // Two pages fetched (initial + empty continuation).
      expect(outcome.pagesFetched, 2);
    });

    test('browse client: skips non-video lockupViewModel '
        '(LOCKUP_CONTENT_TYPE_PLAYLIST)', () async {
      // Lockup view models with non-video content types should not yield a
      // BrowseVideoEntry. The client returns a BrowseFetchOutcome with an
      // empty entries list; the repository's dual-source contract then
      // decides whether to fall back to RSS based on the empty result.
      final body = {
        'contents': {
          'twoColumnBrowseResultsRenderer': {
            'tabs': [
              {
                'tabRenderer': {
                  'content': {
                    'richGridRenderer': {
                      'contents': [
                        {
                          'richItemRenderer': {
                            'content': {
                              'lockupViewModel': {
                                'contentId': 'PLplaylist001',
                                'contentType': 'LOCKUP_CONTENT_TYPE_PLAYLIST',
                                'metadata': {
                                  'lockupMetadataViewModel': {
                                    'title': {'content': 'Playlist Lockup'},
                                  },
                                },
                              },
                            },
                          },
                        },
                        {
                          'continuationItemRenderer': {
                            'continuationEndpoint': {
                              'continuationCommand': {'token': 'CONT'},
                            },
                          },
                        },
                      ],
                    },
                  },
                },
              },
            ],
          },
        },
      };

      final client = YoutubeBrowseClient(
        client: MockClient((req) async {
          final reqBody = jsonDecode(req.body) as Map<String, dynamic>;
          if (reqBody.containsKey('continuation')) {
            return http.Response(
              jsonEncode({
                'contents': {
                  'twoColumnBrowseResultsRenderer': {
                    'tabs': [
                      {
                        'tabRenderer': {
                          'content': {
                            'richGridRenderer': {'contents': []},
                          },
                        },
                      },
                    ],
                  },
                },
              }),
              200,
            );
          }
          return http.Response(jsonEncode(body), 200);
        }),
        profiles: [_webProfile],
      );

      final outcome = await client.fetchChannelVideos(
        channelId: 'UCtestplaylistlockup01',
        fetchedAt: DateTime.utc(2024, 6, 1),
      );

      // The playlist lockup was skipped — no entries were produced.
      expect(outcome.entries, isEmpty);
      // Two pages were fetched (initial + empty continuation).
      expect(outcome.pagesFetched, 2);
    });

    test('browse client: deep search picks up lockupViewModel '
        'wrapped in non-standard containers', () async {
      // Simulates a response where lockupViewModel appears under an
      // unusual top-level wrapper (e.g., when no richGridRenderer /
      // sectionListRenderer is present at all). The deep search must find
      // it.
      final body = {
        'contents': {
          'twoColumnBrowseResultsRenderer': {
            'tabs': [
              {
                'tabRenderer': {
                  'content': {
                    'someUnusualWrapperRenderer': {
                      'items': [
                        {
                          'lockupViewModel': {
                            'contentId': 'deepLockupVid001',
                            'contentType': 'LOCKUP_CONTENT_TYPE_VIDEO',
                            'metadata': {
                              'lockupMetadataViewModel': {
                                'title': {'content': 'Deep Lockup Title'},
                              },
                            },
                          },
                        },
                      ],
                    },
                  },
                },
              },
            ],
          },
        },
      };

      final client = YoutubeBrowseClient(
        client: MockClient((req) async => http.Response(jsonEncode(body), 200)),
        profiles: [_webProfile],
      );

      final outcome = await client.fetchChannelVideos(
        channelId: 'UCtestdeeplockup01',
        fetchedAt: DateTime.utc(2024, 6, 1),
      );

      expect(outcome.entries, hasLength(1));
      expect(outcome.entries.single.videoId, 'deepLockupVid001');
      expect(outcome.entries.single.title, 'Deep Lockup Title');
    });

    test('browse client: parses compactVideoRenderer inside a shelf', () async {
      // The shelf path used to look for `gridVideoRenderer` only; with the
      // refactored extractor, `compactVideoRenderer` (same shape as
      // videoRenderer) is recognised too.
      final body = {
        'contents': {
          'twoColumnBrowseResultsRenderer': {
            'tabs': [
              {
                'tabRenderer': {
                  'content': {
                    'sectionListRenderer': {
                      'contents': [
                        {
                          'itemSectionRenderer': {
                            'contents': [
                              {
                                'shelfRenderer': {
                                  'title': 'Videos',
                                  'content': {
                                    'horizontalListRenderer': {
                                      'items': [
                                        {
                                          'compactVideoRenderer': {
                                            'videoId': 'compactV000001',
                                            'title': {
                                              'runs': [
                                                {'text': 'Compact 1'},
                                              ],
                                            },
                                            'thumbnail': {
                                              'thumbnails': [
                                                {
                                                  'url':
                                                      'https://i.ytimg.com/vi/compactV000001/hqdefault.jpg',
                                                },
                                              ],
                                            },
                                            'lengthText': {
                                              'simpleText': '8:15',
                                            },
                                            'publishedTimeText': {
                                              'simpleText': '5 days ago',
                                            },
                                            'viewCountText': {
                                              'simpleText': '8.1K views',
                                            },
                                          },
                                        },
                                      ],
                                    },
                                  },
                                },
                              },
                            ],
                          },
                        },
                      ],
                    },
                  },
                },
              },
            ],
          },
        },
      };

      final client = YoutubeBrowseClient(
        client: MockClient((req) async => http.Response(jsonEncode(body), 200)),
        profiles: [_webProfile],
      );

      final outcome = await client.fetchChannelVideos(
        channelId: 'UCtestcompact01',
        fetchedAt: DateTime.utc(2024, 6, 1),
      );

      expect(outcome.entries, hasLength(1));
      final entry = outcome.entries.single;
      expect(entry.videoId, 'compactV000001');
      expect(entry.title, 'Compact 1');
      expect(entry.durationSeconds, 495); // 8:15
      expect(
        entry.thumbnailUrl,
        'https://i.ytimg.com/vi/compactV000001/hqdefault.jpg',
      );
      expect(entry.viewCountText, '8.1K views');
    });
  });
}
