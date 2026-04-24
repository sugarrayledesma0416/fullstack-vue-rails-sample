class EbooksPresenter
  BOOKS = {
    61 => { bookshelf_id: '978-1-61857-222-6' },
    59 => { ios_id: '909049726', ios_path: 'mosaik-level-1-ebook', vanity: true },
    62 => { ios_id: '909048929', ios_path: 'mosaik-level-2-ebook', vanity: true },
    63 => { ios_id: '912946020', ios_path: 'mosaik-level-3-ebook', vanity: true },
    72 => { bookshelf_id: '978-1-61857-863-1' },
    73 => { bookshelf_id: '978-1-61857-864-8' },
    68 => { bookshelf_id: '978-1-61857-865-5' },
    80 => { bookshelf_id: '978-68004-027-2' },
    83 => { bookshelf_id: '978-1-62680-637-5' },
    82 => (Rails.env != 'live' && { bookshelf_id: '1889325260' }), # For qa purposes only
    96 => { bookshelf_id: '9781680043198' },
    97 => { bookshelf_id: '9781680043228' },
    98 => { bookshelf_id: '9781680043204' },
    99 => { bookshelf_id: '9781680043211' },
    101 => { bookshelf_id: '9781680043235' },
    107 => { bookshelf_id: '9781680050530' },
    108 => { bookshelf_id: '9781680050943' },
    109 => { bookshelf_id: '9781680051353' },
    112 => { bookshelf_id: '9781680049466' },
    114 => { bookshelf_id: '978-1-68005-190-2' }, # Same as program_id 119
    115 => { bookshelf_id: '978-1-68005-192-6' }, # Same as program_id 120
    116 => { bookshelf_id: '978-1-68005-194-0' }, # Same as program_id 121
    117 => { bookshelf_id: '978-1-68005-196-4' }, # Same as program_id 122
    118 => { bookshelf_id: '978-1-68005-198-8' }, # Same as program_id 123
    119 => { bookshelf_id: '978-1-68005-190-2' }, # Same as program_id 114
    120 => { bookshelf_id: '978-1-68005-192-6' }, # Same as program_id 115
    121 => { bookshelf_id: '978-1-68005-194-0' }, # Same as program_id 116
    122 => { bookshelf_id: '978-1-68005-196-4' }, # Same as program_id 117
    123 => { bookshelf_id: '978-1-68005-198-8' }, # Same as program_id 118
    125 => { bookshelf_id: '9781680058062' }, # Same as program_id 138
    126 => { bookshelf_id: '9781680056280' }, # Same as program_id 134
    127 => { bookshelf_id: '9781680058284' }, # Same as program_id 141
    128 => { bookshelf_id: '9781680057843' }, # Same as program_id 137
    129 => { bookshelf_id: '9781680057409' }, # Same as program_id 139
    130 => { bookshelf_id: '9781680057621' }, # Same as program_id 140
    131 => { bookshelf_id: '9781680056297' }, # Same as program_id 135
    132 => { bookshelf_id: '9781680056730' },
    134 => { bookshelf_id: '9781680056280' }, # Same as program_id 126
    135 => { bookshelf_id: '9781680056297' }, # Same as program_id 131
    137 => { bookshelf_id: '9781680057843' }, # Same as program_id 128
    138 => { bookshelf_id: '9781680058062' }, # Same as program_id 125
    139 => { bookshelf_id: '9781680057409' }, # Same as program_id 129
    140 => { bookshelf_id: '9781680057621' }, # Same as program_id 130
    141 => { bookshelf_id: '9781680058284' }, # Same as program_id 127
    145 => { bookshelf_id: '9781543301298' },
    149 => { bookshelf_id: '978-1-54330-365-0' },
    154 => { bookshelf_id: '9781543301380' },
    156 => { bookshelf_id: '9781543307757' },
    160 => { bookshelf_id: '9781543307542' },
    173 => { bookshelf_id: '978-1-54330-904-1' },
    174 => { bookshelf_id: '978-1-54330-905-8' },
    175 => { bookshelf_id: '978-1-54330-906-5' },
    176 => { bookshelf_id: '9781543310993' }, # Same as program_id 206
    177 => { bookshelf_id: '9781543311020' }, # Same as program_id 207
    178 => { bookshelf_id: '9781543311037' }, # Same as program_id 208
    200 => { bookshelf_id: '9781543316162' },
    201 => { bookshelf_id: '9781543322392' },
    206 => { bookshelf_id: '9781543310993' }, # Same as program_id 176
    207 => { bookshelf_id: '9781543311020' }, # Same as program_id 177
    208 => { bookshelf_id: '9781543311037' }, # Same as program_id 178
    215 => { bookshelf_id: '9781543331912' },
    216 => { bookshelf_id: '9781543311006' }, # Same as program_id 218
    217 => { bookshelf_id: '9781543311013' }, # Same as program_id 219
    218 => { bookshelf_id: '9781543311006' }, # Same as program_id 216
    219 => { bookshelf_id: '9781543311013' }, # Same as program_id 217
    237 => { bookshelf_id: '97815433242111' },
    250 => { bookshelf_id: '9781543335460' },
    251 => { bookshelf_id: '9781543332742' },
    252 => { bookshelf_id: '9781543332759' },
    253 => { bookshelf_id: '9781543332766' },
    254 => { bookshelf_id: '9781543332773' },
    255 => { bookshelf_id: '9781543332780' },
    256 => { bookshelf_id: '9781543332797' },
    257 => { bookshelf_id: '9781543334937' },
    258 => { bookshelf_id: '9781543334944' },
    259 => { bookshelf_id: '9781543334920' },
    260 => { bookshelf_id: '9781543334951' },
    261 => { bookshelf_id: '9781543334968' },
    262 => { bookshelf_id: '9781543331202' },
    263 => { bookshelf_id: '9781543331219' },
    264 => { bookshelf_id: '9781543331226' },
    265 => { bookshelf_id: '9781543331233' },
    266 => { bookshelf_id: '9781543331240' },
    267 => { bookshelf_id: '9781543331202' }, # Same as program_id 262
    268 => { bookshelf_id: '9781543331219' }, # Same as program_id 263
    269 => { bookshelf_id: '9781543331226' }, # Same as program_id 269
    270 => { bookshelf_id: '9781543331233' }, # Same as program_id 265
    271 => { bookshelf_id: '9781543331240' }, # Same as program_id 266
    273 => { bookshelf_id: '9781543331158' },
    274 => { bookshelf_id: '9781543326895' },
    275 => { bookshelf_id: '9781543329117' },
    277 => { bookshelf_id: '9781543335545' },
    278 => { bookshelf_id: '9781543335552' },
    296 => { bookshelf_id: '9781543350739' },
    297 => { bookshelf_id: '9781543350746' },
    298 => { bookshelf_id: '9781543350753' },
    299 => { bookshelf_id: '9781543350760' },
    300 => { bookshelf_id: '9781543350777' },
    301 => { bookshelf_id: '9781543350739' }, # Same as program_id 296
    302 => { bookshelf_id: '9781543350746' }, # Same as program_id 297
    303 => { bookshelf_id: '9781543350753' }, # Same as program_id 298
    304 => { bookshelf_id: '9781543350760' }, # Same as program_id 299
    305 => { bookshelf_id: '9781543350777' }, # Same as program_id 300
    306 => { bookshelf_id: '9781543334920' }, # Same as program_id 259
    307 => { bookshelf_id: '9781543334937' }, # Same as program_id 257
    308 => { bookshelf_id: '9781543334944' }, # Same as program_id 258
    309 => { bookshelf_id: '9781543334951' }, # Same as program_id 260
    310 => { bookshelf_id: '9781543334968' }, # Same as program_id 261
    333 => { bookshelf_id: '9781543357936' },
    334 => { bookshelf_id: '9781543357981' },
    335 => { bookshelf_id: '9781543358025' },
    336 => { bookshelf_id: '9781543358070' },
    337 => { bookshelf_id: '9781543358131' },
    338 => { bookshelf_id: '9781543358193' },
    339 => { bookshelf_id: '9781543358254' },
    340 => { bookshelf_id: '9781543357936' }, # Same as program_id 333
    341 => { bookshelf_id: '9781543357981' }, # Same as program_id 334
    342 => { bookshelf_id: '9781543358025' }, # Same as program_id 335
    343 => { bookshelf_id: '9781543358070' }, # Same as program_id 336
    344 => { bookshelf_id: '9781543358131' }, # Same as program_id 337
    345 => { bookshelf_id: '9781543358193' }, # Same as program_id 338
    346 => { bookshelf_id: '9781543358254' }, # Same as program_id 339
    349 => { bookshelf_id: '9781543362237' },
    350 => { bookshelf_id: '9781543362299' },
    351 => { bookshelf_id: '9781543362312' },
    352 => { bookshelf_id: '9781543362336' },
    353 => { bookshelf_id: '9781543362251' },
    354 => { bookshelf_id: '9781543362275' },
    355 => { bookshelf_id: '9781543362237' }, # Same as program_id 349
    356 => { bookshelf_id: '9781543362299' }, # Same as program_id 350
    357 => { bookshelf_id: '9781543362312' }, # Same as program_id 351
    358 => { bookshelf_id: '9781543362336' }, # Same as program_id 352
    359 => { bookshelf_id: '9781543362251' }, # Same as program_id 353
    360 => { bookshelf_id: '9781543362275' }, # Same as program_id 354
    363 => { bookshelf_id: '9781543357783' },
    364 => { bookshelf_id: '9781543357790' },
    365 => { bookshelf_id: '9781543357806' },
    366 => { bookshelf_id: '9781543357813' },
    367 => { bookshelf_id: '9781543357615' },
    375 => { bookshelf_id: '9781543307757' },
    370 => { bookshelf_id: '9781543362176' },
    371 => { bookshelf_id: '9781543362183' },
    372 => { bookshelf_id: '9781543362190' },
    376 => { bookshelf_id: '9781543307542' },
    377 => { bookshelf_id: '97815433242111' },
    378 => { bookshelf_id: '2015038848' },
    388 => { bookshelf_id: '9781543335545' },
    389 => { bookshelf_id: '9781543335552' },
    392 => { bookshelf_id: '9781543382730' },
    393 => { bookshelf_id: '9781543382747' },
    395 => { bookshelf_id: '9781543381917' },
    397 => { bookshelf_id: '9781543347494' },
    398 => { bookshelf_id: '9781543347500' },
    403 => { bookshelf_id: '9781543375671' },
    405 => { bookshelf_id: '9781543382402' },
    406 => { bookshelf_id: '9781543382426' },
    407 => { bookshelf_id: '9781543382440' },
    408 => { bookshelf_id: '9781543382464' },
    409 => { bookshelf_id: '9781543382488' },
    410 => { bookshelf_id: '9781543382501' },
    414 => { bookshelf_id: '9781543375633' },
    415 => { bookshelf_id: '9781543379693' },
    416 => { bookshelf_id: '9781543379723' },
    417 => { bookshelf_id: '9781543379730' },
    418 => { bookshelf_id: '9781543379709' },
    419 => { bookshelf_id: '9781543379716' },
    420 => { bookshelf_id: '9781543379693' },
    421 => { bookshelf_id: '9781543379723' },
    422 => { bookshelf_id: '9781543379730' },
    423 => { bookshelf_id: '9781543379709' },
    424 => { bookshelf_id: '9781543379716' },
    432 => { bookshelf_id: '9781669913344' },
    433 => { bookshelf_id: '9781669913351' },
    434 => { bookshelf_id: '9781669913368' },
    435 => { bookshelf_id: '9781669913375' },
    436 => { bookshelf_id: '9781669915324' },
    437 => { bookshelf_id: '9781669915355' },
    438 => { bookshelf_id: '9781669915263' },
    439 => { bookshelf_id: '9781669913061' },
    441 => { bookshelf_id: '9781669913573' },
    446 => { bookshelf_id: '9781669913092' },
    447 => { bookshelf_id: '9781669913108' },
    448 => { bookshelf_id: '9781669913078' },
    449 => { bookshelf_id: '9781669913085' },
    450 => { bookshelf_id: '9781669930259' },
    451 => { bookshelf_id: '9781669930259' },
    452 => { bookshelf_id: '9781669930266' },
    453 => { bookshelf_id: '9781669930273' },
    454 => { bookshelf_id: '9781669930280' },
    455 => { bookshelf_id: '9781669930297' },
    456 => { bookshelf_id: '9781669930303' },
    457 => { bookshelf_id: '9781669930266' },
    458 => { bookshelf_id: '9781669930273' },
    459 => { bookshelf_id: '9781669930280' },
    460 => { bookshelf_id: '9781669930297' },
    461 => { bookshelf_id: '9781669930303' },
    462 => { bookshelf_id: '9781669931201' },
    463 => { bookshelf_id: '9781669931232' },
    464 => { bookshelf_id: '9781669931249' },
    465 => { bookshelf_id: '9781669931218' },
    466 => { bookshelf_id: '9781669931225' },
    467 => { bookshelf_id: '9781669931201' },
    468 => { bookshelf_id: '9781669931232' },
    469 => { bookshelf_id: '9781669931249' },
    470 => { bookshelf_id: '9781669931218' },
    471 => { bookshelf_id: '9781669931225' },
    477 => { bookshelf_id: '9781669934264' },
    480 => { bookshelf_id: '9781669934301' },
    481 => { bookshelf_id: '9781669934318' },
    482 => { bookshelf_id: '9781669934325' },
    483 => { bookshelf_id: '9781669934646' },
    484 => { bookshelf_id: '9781669934684' },
    485 => { bookshelf_id: '9781669934691' },
    486 => { bookshelf_id: '9781669934653' },
    487 => { bookshelf_id: '9781669934660' },
    488 => { bookshelf_id: '9781669934677' },
    489 => { bookshelf_id: '9781669934646' },
    490 => { bookshelf_id: '9781669934684' },
    491 => { bookshelf_id: '9781669934691' },
    492 => { bookshelf_id: '9781669934653' },
    493 => { bookshelf_id: '9781669934660' },
    494 => { bookshelf_id: '9781669934677' },
    495 => { bookshelf_id: '9781669930716' },
    496 => { bookshelf_id: '9781669930747' },
    497 => { bookshelf_id: '9781669930754' },
    498 => { bookshelf_id: '9781669930723' },
    499 => { bookshelf_id: '9781669930730' },
    500 => { bookshelf_id: '9781669930716' },
    501 => { bookshelf_id: '9781669930747' },
    502 => { bookshelf_id: '9781669930754' },
    503 => { bookshelf_id: '9781669930723' },
    504 => { bookshelf_id: '9781669930730' },
    505 => { bookshelf_id: '9781543362176' },
    506 => { bookshelf_id: '9781543362183' },
    507 => { bookshelf_id: '9781543362190' },
    508 => { bookshelf_id: '9781669937821' },
    509 => { bookshelf_id: '9781669937937' },
    510 => { bookshelf_id: '9781669913344' },
    511 => { bookshelf_id: '9781669913351' },
    512 => { bookshelf_id: '9781669913368' },
    513 => { bookshelf_id: '9781669913375' },
    514 => { bookshelf_id: '9781669934677' },
    515 => { bookshelf_id: '9781669934677' },
    524 => { bookshelf_id: '9781669947264' },
    525 => { bookshelf_id: '9781669947271' },
    526 => { bookshelf_id: '9781669947288' },
    529 => { bookshelf_id: '9781669947264' },
    530 => { bookshelf_id: '9781669947271' },
    531 => { bookshelf_id: '9781669947288' },
    534 => { bookshelf_id: '9781669947127' },
    535 => { bookshelf_id: '9781669947134' },
    536 => { bookshelf_id: '9781669947127' },
    537 => { bookshelf_id: '9781669947134' }
  }.freeze

  def initialize(program_id)
    @program_id = program_id
  end

  def ebook_released?
    book_data.present?
  end

  def vitalsource_ebook?
    book_data.key?(:bookshelf_id)
  end

  def vitalsource_book_id
    book_data[:bookshelf_id]
  end

  def ios_ebook
    @ios_ebook ||= ios_ebook? && IosEbook.new(book_data)
  end

  def use_smartbanner?
    ios_ebook?
  end

  private def ios_ebook?
    book_data.key?(:ios_id)
  end

  private def book_data
    @book_data ||= (BOOKS[@program_id] || {})
  end

  class IosEbook
    attr_reader :id

    ITUNES_URL = 'https://itunes.apple.com/us/app/'.freeze
    VANITY_URL = 'http://appstore.com/'.freeze

    def initialize(ios_id:, ios_path:, vanity:)
      @id = ios_id
      @ios_path = ios_path
      @vanity = vanity
    end

    def display_url
      if @vanity
        "#{VANITY_URL}#{@ios_path.delete('-')}"
      else
        "#{ITUNES_URL}#{@ios_path}/id#{id}"
      end
    end
  end
end
