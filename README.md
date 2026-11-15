<div align="center">

<a href="https://payam-resan.com">
  <img src=".github/assets/logo.svg" width="64" height="64" alt="پیام رسان">
</a>

<h1>نمونه‌کدهای Delphi وب‌سرویس پیام رسان</h1>

اتصال به وب‌سرویس <a href="https://payam-resan.com"><b>پنل پیامکی پیام رسان</b></a> با Delphi<br>
یک فایل قابل اجرا به‌ازای هر متد سرویس، بدون هیچ وابستگی

[![API](https://img.shields.io/badge/API-V3-0a7cbd)](https://payam-resan.com)
[![Delphi](https://img.shields.io/badge/Delphi-XE8%2B-e62e2e)](https://www.embarcadero.com/products/delphi)
[![Dependencies](https://img.shields.io/badge/dependencies-none-2ea44f)](#شروع-سریع)
[![License](https://img.shields.io/badge/license-MIT-6e7781)](LICENSE)

<b>فارسی</b> · <a href="README.en.md">English</a>

</div>

<sub>دنبال زبان دیگری هستید؟ همین نمونه‌ها برای زبان‌های دیگر هم در
[github.com/Mojeshahr](https://github.com/Mojeshahr) هست.</sub>

---

## شروع سریع

```
git clone https://github.com/Mojeshahr/delphi-sms-webservice.git
cd delphi-sms-webservice

set PAYAM_RESAN_API_KEY=123456-XXXXXXXXXXXXXXX
set PAYAM_RESAN_SENDER=30004040

dcc32 examples\v3\account-info.dpr
account-info.exe
```

نه کامپوننتی لازم است نصب شود و نه بسته‌ای از GetIt. هر دو یونیت
`System.Net.HttpClient` و `System.JSON` در RTL خود دلفی هستند.

با `account-info.dpr` شروع کنید: چیزی ارسال نمی‌کند، اعتباری مصرف نمی‌کند، و
اگر جواب داد یعنی کلید و اتصال هر دو سالم‌اند.

## دو مجموعه نمونه، عمداً

پوشه `examples/v3/` با `THTTPClient` نوشته شده که از XE8 به بعد در RTL هست،
TLS را روی ویندوز از خود سیستم می‌گیرد و نصب هیچ چیزی نمی‌خواهد. اگر پروژه
تازه‌ای می‌نویسید یا دلفی‌تان به‌روز است، همین را بردارید.

پوشه `examples/v3-indy/` همان یازده متد را با `TIdHTTP` دارد. برای کسی است که
نرم‌افزار قدیمی‌تری را نگه می‌دارد و کل پروژه‌اش روی Indy سوار است. آنجا افزودن
یک مسیر HTTP تازه یعنی دردسر، و بازنویسی هم گزینه نیست.

<div dir="rtl">

| | `examples/v3/` | `examples/v3-indy/` |
|---|---|---|
| کلاس HTTP | `THTTPClient` | `TIdHTTP` |
| کف نسخه | XE8 | XE6 |
| TLS روی ویندوز | از خود سیستم | فایل‌های OpenSSL کنار برنامه |
| نصب کامپوننت | ندارد | Indy همراه دلفی می‌آید |

</div>

یک نکته را روشن بگوییم تا انتظار غلط نسازیم: هر دو مجموعه برای خواندن JSON از
`System.JSON` استفاده می‌کنند که از XE6 در RTL هست. پس مجموعه Indy فقط لایه
HTTP را عوض می‌کند، نه کف نسخه را تا دلفی ۷. اگر روی نسخه‌ای پیش از XE6 هستید،
بخش JSON را باید با کتابخانه‌ای مثل SuperObject جایگزین کنید و بقیه کد سر جایش
می‌ماند.

اگر آزادید انتخاب کنید، مجموعه اول را بردارید. تنظیم OpenSSL برای Indy رایج‌ترین
منبع خطا در این مسیر است.

## پیش از ارسال واقعی

یک سرور آزمایشی هست که مثل سرور عملیاتی جواب می‌دهد ولی پیامکی نمی‌فرستد و
اعتباری مصرف نمی‌کند. کافی است `V3` در نشانی را با `V3SandBox` عوض کنید. تنها
استثنا `TokenList` است که روی آن سرور پیاده نشده.

## متدها

<div dir="rtl">

| نمونه | متد | کار |
|---|---|---|
| [account-info.dpr](examples/v3/account-info.dpr) | `AccountInfo` | اعتبار و خطوط فعال |
| [send.dpr](examples/v3/send.dpr) | `Send` | ارسال ساده با `GET` |
| [send-bulk.dpr](examples/v3/send-bulk.dpr) | `SendBulk` | یک متن به چند گیرنده، با شناسه پی‌گیری |
| [send-multiple.dpr](examples/v3/send-multiple.dpr) | `SendMultiple` | متن جدا برای هر گیرنده |
| [token-list.dpr](examples/v3/token-list.dpr) | `TokenList` | فهرست قالب‌ها |
| [send-token-single.dpr](examples/v3/send-token-single.dpr) | `SendTokenSingle` | ارسال قالب به یک شماره |
| [send-token-single-get.dpr](examples/v3/send-token-single-get.dpr) | `SendTokenSingle` | همان، با `GET` |
| [send-token-single-concat-param.dpr](examples/v3/send-token-single-concat-param.dpr) | `SendTokenSingleConcatParam` | مقادیر قالب در رشته `p` با جداکننده نقطه‌ویرگول |
| [send-token-single-concat-param-get.dpr](examples/v3/send-token-single-concat-param-get.dpr) | `SendTokenSingleConcatParam` | همان، با `GET` |
| [send-token-multi.dpr](examples/v3/send-token-multi.dpr) | `SendTokenMulti` | یک قالب، چند گیرنده |
| [status-by-id.dpr](examples/v3/status-by-id.dpr) | `StatusById` | وضعیت با شناسه سامانه |
| [status-by-user-trace-id.dpr](examples/v3/status-by-user-trace-id.dpr) | `StatusByUserTraceId` | وضعیت با شناسه خودتان |
| [get-inbox.dpr](examples/v3/get-inbox.dpr) | `GetInbox` | پیامک‌های رسیده |

</div>

همین یازده نام در `examples/v3-indy/` هم تکرار شده‌اند.

## اگر به خطا خوردید، خبرمان کنید

اینجا یک چیز را رک می‌گوییم. کامپایلر دلفی فقط روی ویندوز و تجاری است، پس
نمونه‌های این مخزن با Free Pascal در حالت سازگاری دلفی کامپایل و اجرا شده‌اند،
نه با خود `dcc32`. روش کارش در [`testing/`](testing/) توضیح داده شده.

یعنی نحو و ساختار و امضای فراخوانی‌ها بررسی شده، ولی یک بار کامپایل روی
RAD Studio واقعی جای خودش را دارد.

پس اگر روی نسخه دلفی خودتان به خطای کامپایل، هشدار، یا رفتار متفاوتی خوردید،
دقیقاً همان چیزی است که می‌خواهیم بشنویم. یک
[issue](https://github.com/Mojeshahr/delphi-sms-webservice/issues) باز کنید و
نسخه دلفی، نام فایل و متن خطا را بنویسید. Pull request هم با آغوش باز.

نمونه‌ای که واقعاً روی نسخه شما کامپایل می‌شود از نمونه‌ای که فقط تمیز به نظر
می‌رسد ارزش بیشتری دارد.

## چند نکته که وقت‌تان را می‌خرد

**کد وضعیت HTTP را نخوانید.** سرویس همیشه `200` برمی‌گرداند، حتی وقتی کلید
اشتباه است، پس `Answer.StatusCode` چیزی ثابت نمی‌کند. تصمیم را از فیلد
`Success` بگیرید. هر نمونه اینجا همین کار را می‌کند.

**بدنه را با `TEncoding.UTF8` بسازید.** اگر `TStringStream` را بدون آن بسازید،
متن فارسی با کدپیج پیش‌فرض ویندوز می‌رود و پیامک به‌شکل علامت سؤال به گوشی
می‌رسد.

**شماره گیرنده صفر ابتدایی ندارد.** یعنی `9121112222` یا با کد کشور
`989121112222`. شماره‌ای که با `9` یا `989` شروع نشود کد خطای `13` می‌گیرد.

**برای هر گیرنده یک `UserTraceId` یکتا بفرستید.** بعد از یک timeout، این تنها
راه فهمیدن این است که پیامک ثبت شده یا نه.

## امنیت کلید

کلید یک راز است. در مخزن کد، در جاوااسکریپت مرورگر و در بسته اپلیکیشن موبایل
نباید قرار بگیرد. جای آن متغیر محیطی است، همان‌طور که همه نمونه‌ها می‌خوانندش.

اگر کلیدی لو رفت، از پنل یکی تازه بسازید. کلید حذف‌شده برنمی‌گردد.

## ساختار

<div dir="rtl">

| مسیر | چه چیزی دارد |
|---|---|
| `examples/v3/` | یک نمونه مستقل با `THTTPClient` به‌ازای هر عملیات |
| `examples/v3-indy/` | همان‌ها با `TIdHTTP` برای پروژه‌های قدیمی‌تر |
| `testing/` | ابزار کامپایل روی لینوکس و شرح آنچه ثابت می‌کند |
| `.env.example` | نمونه متغیرهای محیطی |

</div>

عدد `v3` در مسیر عمدی است. نسخه تازه سرویس یعنی پوشه `examples/v<n>/` تازه، و
پوشه موجود دست‌نخورده می‌ماند.

## مستندات و پشتیبانی

راهنمای کامل وب‌سرویس در [docs.payam-resan.com](https://docs.payam-resan.com)
است. توصیف ماشین‌خوان OpenAPI هم در
[sms-webservice-spec](https://github.com/Mojeshahr/sms-webservice-spec).

سؤال یا خطایی هست؟ [issue باز کنید](https://github.com/Mojeshahr/delphi-sms-webservice/issues)
یا با [پشتیبانی](https://payam-resan.com) تماس بگیرید.

## مجوز

منتشرشده با مجوز MIT. متن کامل در [`LICENSE`](LICENSE).

<br>
<div align="center">
  <sub>
    <img src=".github/assets/logo.svg" width="16" height="16" alt="" align="top">
    &nbsp;<b>پنل پیامکی پیام رسان - موج شهر</b>&nbsp;
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset=".github/assets/mojeshahr-dark.svg">
      <img src=".github/assets/mojeshahr-light.svg" width="16" height="16" alt="" align="top">
    </picture>
  </sub>
  <br>
  <sub>
    <a href="https://payam-resan.com">payam-resan.com</a>
    &nbsp;·&nbsp;
    <a href="https://mojeshahr.ir">mojeshahr.ir</a>
  </sub>
</div>
