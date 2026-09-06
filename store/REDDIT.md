# Reddit — nereye, ne zaman, ne yazarak

İki metin ve bir sıra. Metinler İngilizce, çünkü hedef kitlenin dili o; bu
dosyanın kendisi Türkçe, çünkü onu sen okuyacaksın.

---

## Önce: neyi doğrulayabildim, neyi doğrulayamadım

Reddit'in kural sayfaları buradan çekilemiyor, o yüzden ayrımı açık tutuyorum.

| Subreddit | Kural durumu | Kaynak |
|---|---|---|
| **r/SideProject** | **Doğrulandı** — kendi tanıtımın açıkça hoş karşılanıyor. Kapı karma değil, "bunu gerçekten sen mi yaptın ve gerçek bir yapımcı gibi mi anlatıyorsun". Yeni hesapsan önce bir hafta yorum yap. | [GrowReddit](https://www.growreddit.com/blog/reddit-self-promotion-rules-sideproject), [OneUp](https://oneup.today/tools/reddit-self-promotion-checker/sideproject) |
| **r/androidapps** | **Doğrulandı** — kurallarla birlikte izin veriliyor. İlk cümlede geliştirici olduğunu açıkla, gerçek ekran görüntüsü koy, mağaza rozeti değil. | [ReachFront](https://reachfront.ai/guides/reddit-marketing-for-apps), [MediaFast](https://www.mediafa.st/how-to-promote/mobile-app-on-reddit) |
| **r/languagelearning** | **Kısmen** — "şartlarla izinli". "Kendi içeriğini çok sık gönderme" kuralı var; genelde bu ayrı bir haftalık başlık, zorunlu flair veya mod onayı demek. **Göndermeden önce kenar çubuğunu oku.** | [LeadsRover](https://leadsrover.io/subreddits/r/languagelearning) |
| **r/EnglishLearning** | **Doğrulanamadı** — 707 bin üye, topluluk uygulama önerilerini ve incelemelerini sık konuşuyor, ama kendi tanıtım kuralını teyit edemedim. **Kenar çubuğunu okumadan gönderme.** | [GummySearch](https://gummysearch.com/r/EnglishLearning/) |

Her yer için geçerli olan üçü, ve bunlar doğrulandı:

1. **90/10.** Etkinliğinin en az %90'ı gerçek katılım olmalı. Sadece kendi
   gönderin için ortaya çıkan hesap görmezden gelinir.
2. **İlk cümlede geliştirici olduğunu söyle.** Saklamaya çalışmak, yakalanınca
   gönderiyi de hesabı da bitiriyor.
3. **Kısaltılmış veya takipli link kullanma.** `bit.ly`, UTM parametresi,
   yönlendirme kodu — otomatik spam filtreleri bunları eliyor. Düz Play linki.

---

## Sıra

Aynı gün hepsine atma. `signup_completed` artık çalışıyor, yani ilk kez hangi
gönderinin kullanıcı getirdiğini **ölçebilirsin** — ama sadece aralarında
boşluk bırakırsan.

1. **Gün 1 — r/SideProject.** En güvenli ve kuralları en net olan. Metin A.
2. **Gün 3 — Play Console → Yüklemeler'e bak.** Ne geldi?
3. **Gün 4 — r/androidapps.** Metin A'nın kısaltılmışı, ekran görüntüsüyle.
4. **Gün 6 — tekrar bak.**
5. **Sonra r/languagelearning**, kenar çubuğunu okuduktan sonra. Metin B.
6. **En son r/EnglishLearning**, kuralları teyit edersen. Metin B.

Sondaki ikisi en değerli kitle *ve* en sıkı kurallar — o yüzden en sona
bırakıyoruz, sen o zamana kadar Reddit'te birkaç gerçek yorum yapmış olursun.

---

## Metin A — yapımcı kitlesi (r/SideProject, r/androidapps)

Bu gönderi ürünü satmıyor, bir kararı anlatıyor. r/SideProject'te tutan şey
bu: dürüst bir ders, reklam değil. Hikâye gerçek — bu haftaki bir günün
tamamı buydu.

**Başlık:**

```
I was about to ship pronunciation scoring in my English app. Reading my own code stopped me.
```

**Gövde:**

```
I'm a solo developer. For the last six months I've been building an English
learning app, and this week I nearly shipped the feature every competitor
sells: a pronunciation score.

The plan was reasonable. I use Whisper for speech-to-text, and Whisper's
verbose response includes `avg_logprob` — how confident the model was in what
it transcribed. Low confidence, bad pronunciation, show the learner a score.
Every speaking app on the store has one. Mine didn't.

Three things stopped me, in order:

**1. There is no per-word confidence.** A word object from Whisper carries
`word`, `start` and `end`. That's it. `avg_logprob` exists per *segment* —
roughly per sentence. There is nothing to score a word against.

**2. My own repository had already written the reason down.** I went looking
in my speech service and found a comment I'd left months ago while building a
silence detector: low log-probability alone "fires on unusual accents." Every
single user of my app has an unusual accent by that model's standards. That is
the entire point of the app. A score built on it would have marked a Turkish
speaker down for sounding Turkish.

**3. I watched it happen.** Testing on my phone the same day, I said "Hi Amy"
to the tutor. Whisper transcribed "Hi Emi." That is the model missing a name,
and a pronunciation score would have reported it to the learner as their
mistake.

So I didn't build it. What I built instead was sitting in the response the
whole time: Whisper returns word-level *timestamps*, and my backend had been
fetching them, parsing them into a struct, and sending them to the app, where
the client read the transcript and threw the array away. Timings carry no
judgement — pace and hesitation are arithmetic on when words started and
stopped, true whatever your accent.

Now a turn shows "62 words/min · 2 pauses" under your own sentence. No colour,
no threshold, no "too slow." 62 is only slow next to a native speaker and
nobody opens a language app already being one. What makes it worth showing is
watching it climb.

The rest of the app, briefly: you hold a button and talk to a tutor who
answers out loud in character (ordering coffee, hotel check-in, a doctor's
appointment), and when you say something that could be said better, the better
version appears under your own reply. You read whole public-domain books —
Sherlock Holmes, Aesop, Wilde — and tap any word to get its meaning *inside the
sentence it came from*, not a dictionary entry with nine definitions. Saved
words come back for review on the day you're about to forget them.

Free: word list, reviews, books, grammar. Paid: the AI features, on a quota.
No ads, no leaderboard, no streak that guilt-trips you.

https://play.google.com/store/apps/details?id=com.VocabMaster

I'd genuinely like to be told what's wrong with it. Especially: is showing a
words-per-minute number motivating or discouraging? I went back and forth on
it for a day and I still don't know.
```

**Neden bu metin çalışır:** ilk cümlede kim olduğunu söylüyor · bir şey
*öğretiyor* (Whisper'ın gerçek sınırları, teknik ve doğrulanabilir) · kendi
aleyhine bir karar anlatıyor · link sonda ve düz · gerçek bir soru soruyor.

**r/androidapps için:** ilk üç bölümü at, "The rest of the app, briefly"den
başla, başlığı `I built an English app where you read real books and tap words
for in-context meanings — feedback wanted` yap ve **iki ekran görüntüsü** ekle
(kitaplık ve eğitmen; `store/play/screenshot_en_03.png` ve
`screenshot_en_01.png` iş görür).

---

## Metin B — öğrenen kitlesi (r/languagelearning, sonra r/EnglishLearning)

Burada ürün değil, **çözdüğü sorun** öne çıkıyor. Bu topluluklar reklamdan
hızla sıkılıyor ama "şunu şöyle çözmeye çalıştım, sizce doğru mu" sorusuna
açıklar.

**Başlık:**

```
Dictionary definitions never matched the sentence I was reading, so I built a reader that explains the word in context. Would like your criticism.
```

**Gövde:**

```
I'm the developer — saying that first so nobody has to wonder.

The thing that made me start: I'd be reading something in English, hit a word
I didn't know, look it up, and get nine definitions of which exactly one was
relevant to the sentence in front of me. Picking the right one is a skill you
need the vocabulary to have. So the lookup taught me the least at exactly the
moment I understood the least.

What I ended up building is a reader over public-domain books — Sherlock
Holmes, Aesop's Fables, The Happy Prince, Jekyll and Hyde, sorted by CEFR
level — where tapping a word explains *that* word in *that* sentence. One
meaning, the one on the page. A second tap saves it, with the sentence
attached, and it comes back for review on the day you're about to lose it.

Two other things are in there: a tutor you can talk to out loud in a specific
situation (ordering coffee, checking into a hotel, explaining a symptom at the
doctor), which corrects you by showing a better version of your own sentence
rather than marking it wrong; and translation practice built from the words
*you* saved rather than a fixed list.

Things I deliberately did not do, in case they matter to you: no ads, no
leaderboard, no streak that shames you when you miss a day, and today's plan is
finite — you can finish it and be done.

The reading, the word list, the reviews and the grammar guides are free. The AI
parts run on a quota with a paid tier. I'm not going to pretend that isn't a
business; I'd rather say it plainly than bury it.

https://play.google.com/store/apps/details?id=com.VocabMaster

What I actually want from this post is criticism. Specifically:

- Is in-context definition genuinely better than a dictionary entry, or does it
  hide useful information you'd want?
- Does reading a whole 19th-century book help modern English, or am I teaching
  people to speak like Conan Doyle?

I'll answer everything in the comments.
```

**Uyarı:** İkinci soru gerçek bir eleştiriyi davet ediyor ve alacaksın —
kütüphane kamu malı olduğu için hepsi eski metin. Bu bilinçli: kendin sormak,
başkasının vurmasından iyidir, ve cevabın hazır olmalı (seviyeye göre sıralı,
ve kaydettiğin kelimeler modern konuşma pratiğinde geri geliyor).

---

## Göndermeden önceki kontrol listesi

- [ ] Hesabın birkaç günlük gerçek yorum geçmişi var mı? Yoksa önce onu yap.
- [ ] O subreddit'in kenar çubuğunu **bugün** okudun mu? Kurallar değişiyor.
- [ ] Link düz Play linki mi? (UTM yok, kısaltma yok)
- [ ] İlk cümlede geliştirici olduğunu söylüyor musun?
- [ ] Gönderiden sonraki 2 saat müsait misin? İlk saatteki cevaplar
      gönderinin görünürlüğünü belirliyor; sorulara cevap vermezsen ölür.
- [ ] Play Console → Yüklemeler'in bugünkü sayısını not aldın mı? Ölçüm
      karşılaştırma gerektirir.
