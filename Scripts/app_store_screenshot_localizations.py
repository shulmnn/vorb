#!/usr/bin/env python3
"""Reviewed screenshot copy for Vorb's launch localization set."""

LOCALIZATIONS = {
    "en-US": {
        "brand": "WHISPER DICTATION FOR macOS",
        "screens": [
            {
                "headline": "Your thoughts.\nAlready typed.",
                "supporting": "Speak naturally. Vorb turns your voice into text before the idea disappears.",
                "pills": ["SPEECH → TEXT", "⌥ SPACE", "COPY ANYWHERE"],
            },
            {
                "headline": "Say it.\nPaste it.",
                "supporting": "One shortcut turns your voice into text you can paste wherever you work.",
                "pills": ["VOICE", "→", "TEXT"],
                "transcript_label": "TRANSCRIBED TEXT",
                "transcript": "Remember to send the final draft\nbefore lunch.",
                "ready": "READY TO PASTE",
            },
            {
                "headline": "One voice.\nEvery writing task.",
                "supporting": "Dictate notes, emails, messages, and prompts—then paste the result wherever you work.",
                "pills": ["EMAIL", "NOTES", "MESSAGES"],
            },
            {
                "headline": "Whisper stays here.\nSo do your words.",
                "supporting": "On-device speech-to-text. No API key. No audio upload.",
                "pills": ["NO KEY", "ON-DEVICE", "CORE ML"],
            },
            {
                "headline": "Your keys.\nZero lock-in.",
                "supporting": "Connect Groq, OpenAI, Deepgram, or any compatible speech-to-text endpoint.",
                "pills": ["GROQ", "OPENAI", "DEEPGRAM", "+ MORE"],
            },
            {
                "headline": "Fast or accurate?\nYou decide.",
                "supporting": "Pick the Whisper model and language that fit the moment.",
                "pills": ["TINY", "BASE", "SMALL", "LARGE V3"],
            },
            {
                "headline": "Never lose a\ngood thought again.",
                "supporting": "Keep an optional local transcript history, ready to copy when you need it.",
                "pills": ["LOCAL HISTORY", "COPY", "DELETE"],
            },
            {
                "headline": "Tap once.\nOr hold and talk.",
                "supporting": "Choose any global shortcut and make voice typing feel automatic.",
                "pills": ["⌥ SPACE", "TOGGLE", "HOLD"],
            },
        ],
    },
    "de-DE": {
        "brand": "WHISPER-DIKTIEREN FÜR macOS",
        "screens": [
            {"headline": "Gedanken.\nSchon getippt.", "supporting": "Sprich einfach drauflos. Vorb verwandelt deine Stimme in Text, bevor die Idee verloren geht.", "pills": ["SPRACHE → TEXT", "⌥ LEERTASTE", "ÜBERALL EINFÜGEN"]},
            {"headline": "Sag es.\nFüge es ein.", "supporting": "Ein Kurzbefehl macht aus deiner Stimme Text für jede App.", "pills": ["STIMME", "→", "TEXT"], "transcript_label": "TRANSKRIBIERTER TEXT", "transcript": "Denk daran, den finalen Entwurf\nvor dem Mittagessen zu senden.", "ready": "BEREIT ZUM EINFÜGEN"},
            {"headline": "Eine Stimme.\nFür jede Schreibaufgabe.", "supporting": "Diktiere Notizen, E-Mails, Nachrichten und Prompts – und füge den Text überall ein.", "pills": ["E-MAIL", "NOTIZEN", "NACHRICHTEN"], "headline_size": 100},
            {"headline": "Whisper bleibt hier.\nDeine Worte auch.", "supporting": "Spracherkennung auf dem Mac. Kein API-Schlüssel. Kein Audio-Upload.", "pills": ["OHNE SCHLÜSSEL", "AUF DEM MAC", "CORE ML"], "headline_size": 104},
            {"headline": "Deine Schlüssel.\nKeine Bindung.", "supporting": "Verbinde Groq, OpenAI, Deepgram oder jeden kompatiblen Speech-to-Text-Dienst.", "pills": ["GROQ", "OPENAI", "DEEPGRAM", "UND MEHR"]},
            {"headline": "Schnell oder genau?\nDu entscheidest.", "supporting": "Wähle das Whisper-Modell und die Sprache, die gerade passen.", "pills": ["TINY", "BASE", "SMALL", "LARGE V3"], "headline_size": 104},
            {"headline": "Kein guter Gedanke\ngeht mehr verloren.", "supporting": "Speichere optional einen lokalen Verlauf und kopiere Text jederzeit erneut.", "pills": ["LOKALER VERLAUF", "KOPIEREN", "LÖSCHEN"], "headline_size": 94},
            {"headline": "Einmal tippen.\nOder halten und sprechen.", "supporting": "Lege deinen Kurzbefehl fest und diktiere ganz automatisch.", "pills": ["⌥ LEERTASTE", "UMSCHALTEN", "HALTEN"], "headline_size": 94},
        ],
    },
    "fr-FR": {
        "brand": "DICTÉE WHISPER POUR macOS",
        "screens": [
            {"headline": "Vos idées.\nDéjà écrites.", "supporting": "Parlez naturellement. Vorb transforme votre voix en texte avant que l’idée ne s’échappe.", "pills": ["VOIX → TEXTE", "⌥ ESPACE", "COLLER PARTOUT"]},
            {"headline": "Dites-le.\nCollez-le.", "supporting": "Un raccourci transforme votre voix en texte à coller partout.", "pills": ["VOIX", "→", "TEXTE"], "transcript_label": "TEXTE TRANSCRIT", "transcript": "Pense à envoyer la version finale\navant midi.", "ready": "PRÊT À COLLER"},
            {"headline": "Une voix.\nTous vos écrits.", "supporting": "Dictez notes, e-mails, messages et prompts, puis collez le résultat où vous voulez.", "pills": ["E-MAIL", "NOTES", "MESSAGES"]},
            {"headline": "Whisper reste ici.\nVos mots aussi.", "supporting": "Reconnaissance vocale locale. Sans clé API. Aucun envoi audio.", "pills": ["SANS CLÉ", "SUR LE MAC", "CORE ML"]},
            {"headline": "Vos clés.\nAucun verrouillage.", "supporting": "Connectez Groq, OpenAI, Deepgram ou tout service compatible de transcription.", "pills": ["GROQ", "OPENAI", "DEEPGRAM", "ET PLUS"]},
            {"headline": "Rapide ou précis ?\nÀ vous de choisir.", "supporting": "Choisissez le modèle Whisper et la langue adaptés à chaque moment.", "pills": ["TINY", "BASE", "SMALL", "LARGE V3"], "headline_size": 104},
            {"headline": "Ne perdez plus\nune bonne idée.", "supporting": "Gardez un historique local facultatif, prêt à être recopié.", "pills": ["HISTORIQUE LOCAL", "COPIER", "SUPPRIMER"]},
            {"headline": "Appuyez une fois.\nOu maintenez pour parler.", "supporting": "Choisissez votre raccourci et dictez naturellement.", "pills": ["⌥ ESPACE", "BASCULE", "MAINTENIR"], "headline_size": 96},
        ],
    },
    "es-ES": {
        "brand": "DICTADO WHISPER PARA macOS",
        "screens": [
            {"headline": "Tus ideas.\nYa escritas.", "supporting": "Habla con naturalidad. Vorb convierte tu voz en texto antes de que la idea desaparezca.", "pills": ["VOZ → TEXTO", "⌥ ESPACIO", "PEGAR DONDE QUIERAS"]},
            {"headline": "Dilo.\nPégalo.", "supporting": "Un atajo convierte tu voz en texto listo para pegar en cualquier app.", "pills": ["VOZ", "→", "TEXTO"], "transcript_label": "TEXTO TRANSCRITO", "transcript": "Recuerda enviar el borrador final\nantes del almuerzo.", "ready": "LISTO PARA PEGAR"},
            {"headline": "Una voz.\nPara todo lo que escribes.", "supporting": "Dicta notas, correos, mensajes y prompts; después pega el texto donde quieras.", "pills": ["CORREO", "NOTAS", "MENSAJES"], "headline_size": 100},
            {"headline": "Whisper se queda aquí.\nTus palabras también.", "supporting": "Voz a texto en tu Mac. Sin clave API. Sin subir audio.", "pills": ["SIN CLAVE", "EN EL MAC", "CORE ML"], "headline_size": 96},
            {"headline": "Tus claves.\nSin ataduras.", "supporting": "Conecta Groq, OpenAI, Deepgram o cualquier servicio compatible.", "pills": ["GROQ", "OPENAI", "DEEPGRAM", "+ MÁS"]},
            {"headline": "¿Rapidez o precisión?\nTú decides.", "supporting": "Elige el modelo Whisper y el idioma adecuados para cada momento.", "pills": ["TINY", "BASE", "SMALL", "LARGE V3"], "headline_size": 100},
            {"headline": "No pierdas otra\nbuena idea.", "supporting": "Guarda un historial local opcional y copia cualquier texto cuando quieras.", "pills": ["HISTORIAL LOCAL", "COPIAR", "ELIMINAR"]},
            {"headline": "Pulsa una vez.\nO mantén para hablar.", "supporting": "Elige cualquier atajo y dicta de forma natural.", "pills": ["⌥ ESPACIO", "ALTERNAR", "MANTENER"], "headline_size": 102},
        ],
    },
    "pt-BR": {
        "brand": "DITADO WHISPER PARA macOS",
        "screens": [
            {"headline": "Suas ideias.\nJá digitadas.", "supporting": "Fale naturalmente. O Vorb transforma sua voz em texto antes que a ideia desapareça.", "pills": ["VOZ → TEXTO", "⌥ ESPAÇO", "COLAR EM QUALQUER LUGAR"]},
            {"headline": "Fale.\nCole.", "supporting": "Um atalho transforma sua voz em texto pronto para colar em qualquer app.", "pills": ["VOZ", "→", "TEXTO"], "transcript_label": "TEXTO TRANSCRITO", "transcript": "Lembre-se de enviar a versão final\nantes do almoço.", "ready": "PRONTO PARA COLAR"},
            {"headline": "Uma voz.\nTodo tipo de texto.", "supporting": "Dite notas, e-mails, mensagens e prompts; depois cole onde quiser.", "pills": ["E-MAIL", "NOTAS", "MENSAGENS"]},
            {"headline": "Whisper fica aqui.\nSuas palavras também.", "supporting": "Voz em texto no seu Mac. Sem chave de API. Sem envio de áudio.", "pills": ["SEM CHAVE", "NO MAC", "CORE ML"], "headline_size": 100},
            {"headline": "Suas chaves.\nSem dependência.", "supporting": "Conecte Groq, OpenAI, Deepgram ou qualquer serviço compatível.", "pills": ["GROQ", "OPENAI", "DEEPGRAM", "+ MAIS"]},
            {"headline": "Rápido ou preciso?\nVocê decide.", "supporting": "Escolha o modelo Whisper e o idioma ideais para cada momento.", "pills": ["TINY", "BASE", "SMALL", "LARGE V3"], "headline_size": 104},
            {"headline": "Nunca perca\numa boa ideia.", "supporting": "Mantenha um histórico local opcional e copie seus textos quando quiser.", "pills": ["HISTÓRICO LOCAL", "COPIAR", "EXCLUIR"]},
            {"headline": "Toque uma vez.\nOu segure para falar.", "supporting": "Escolha qualquer atalho e dite naturalmente.", "pills": ["⌥ ESPAÇO", "ALTERNAR", "SEGURAR"], "headline_size": 102},
        ],
    },
    "it": {
        "brand": "DETTATURA WHISPER PER macOS",
        "screens": [
            {"headline": "I tuoi pensieri.\nGià scritti.", "supporting": "Parla naturalmente. Vorb trasforma la tua voce in testo prima che l’idea svanisca.", "pills": ["VOCE → TESTO", "⌥ SPAZIO", "INCOLLA OVUNQUE"]},
            {"headline": "Dillo.\nIncollalo.", "supporting": "Una scorciatoia trasforma la voce in testo da incollare ovunque.", "pills": ["VOCE", "→", "TESTO"], "transcript_label": "TESTO TRASCRITTO", "transcript": "Ricordati di inviare la bozza finale\nprima di pranzo.", "ready": "PRONTO DA INCOLLARE"},
            {"headline": "Una voce.\nOgni testo che scrivi.", "supporting": "Detta note, e-mail, messaggi e prompt, poi incolla il risultato dove vuoi.", "pills": ["E-MAIL", "NOTE", "MESSAGGI"], "headline_size": 102},
            {"headline": "Whisper resta qui.\nAnche le tue parole.", "supporting": "Voce in testo sul Mac. Nessuna chiave API. Nessun upload audio.", "pills": ["SENZA CHIAVE", "SUL MAC", "CORE ML"], "headline_size": 100},
            {"headline": "Le tue chiavi.\nNessun vincolo.", "supporting": "Collega Groq, OpenAI, Deepgram o qualsiasi servizio compatibile.", "pills": ["GROQ", "OPENAI", "DEEPGRAM", "+ ALTRO"]},
            {"headline": "Veloce o accurato?\nDecidi tu.", "supporting": "Scegli il modello Whisper e la lingua più adatti al momento.", "pills": ["TINY", "BASE", "SMALL", "LARGE V3"], "headline_size": 104},
            {"headline": "Non perdere più\nuna buona idea.", "supporting": "Conserva una cronologia locale facoltativa e ricopia qualsiasi testo.", "pills": ["CRONOLOGIA LOCALE", "COPIA", "ELIMINA"]},
            {"headline": "Premi una volta.\nOppure tieni premuto.", "supporting": "Scegli la scorciatoia e detta in modo naturale.", "pills": ["⌥ SPAZIO", "ATTIVA", "TIENI PREMUTO"], "headline_size": 96},
        ],
    },
    "ja": {
        "brand": "macOS用WHISPER音声入力",
        "screens": [
            {"headline": "考えたことが、\nもう文字に。", "supporting": "自然に話すだけ。アイデアが消える前に、Vorbが声を文字にします。", "pills": ["音声 → テキスト", "⌥ スペース", "どこでもペースト"], "headline_size": 104},
            {"headline": "話す。\n貼り付ける。", "supporting": "ショートカットひとつで、声がすぐに使えるテキストになります。", "pills": ["音声", "→", "テキスト"], "transcript_label": "文字起こし結果", "transcript": "最終稿を昼までに送ることを\n忘れないで。", "ready": "ペーストできます", "headline_size": 106},
            {"headline": "ひとつの声で、\nすべてを書く。", "supporting": "メモ、メール、メッセージ、プロンプトを音声入力。結果はどこにでも貼り付けられます。", "pills": ["メール", "メモ", "メッセージ"], "headline_size": 104},
            {"headline": "Whisperはここに。\n言葉もここに。", "supporting": "Mac内で音声をテキスト化。APIキー不要。音声の送信なし。", "pills": ["キー不要", "デバイス上", "CORE ML"], "headline_size": 102},
            {"headline": "自分のキーで。\nロックインなし。", "supporting": "Groq、OpenAI、Deepgramなど、対応サービスへ接続できます。", "pills": ["GROQ", "OPENAI", "DEEPGRAM", "+ その他"], "headline_size": 104},
            {"headline": "速さか精度か。\n選ぶのはあなた。", "supporting": "用途に合うWhisperモデルと言語を選べます。", "pills": ["TINY", "BASE", "SMALL", "LARGE V3"], "headline_size": 102},
            {"headline": "大切なアイデアを、\nもう失わない。", "supporting": "任意のローカル履歴に保存し、いつでもコピーできます。", "pills": ["ローカル履歴", "コピー", "削除"], "headline_size": 100},
            {"headline": "一度押す。\nまたは押して話す。", "supporting": "好きなショートカットで、自然に音声入力できます。", "pills": ["⌥ スペース", "切り替え", "長押し"], "headline_size": 102},
        ],
    },
    "ko": {
        "brand": "macOS용 WHISPER 받아쓰기",
        "screens": [
            {"headline": "생각이 벌써\n글이 됩니다.", "supporting": "자연스럽게 말하세요. 아이디어가 사라지기 전에 Vorb가 텍스트로 바꿉니다.", "pills": ["음성 → 텍스트", "⌥ 스페이스", "어디서나 붙여넣기"], "headline_size": 104},
            {"headline": "말하고.\n붙여넣기.", "supporting": "단축키 하나로 음성을 어디서나 쓸 수 있는 텍스트로 바꿉니다.", "pills": ["음성", "→", "텍스트"], "transcript_label": "변환된 텍스트", "transcript": "점심 전에 최종본을 보내는 것을\n잊지 마세요.", "ready": "붙여넣기 준비 완료", "headline_size": 106},
            {"headline": "하나의 목소리로\n모든 글쓰기.", "supporting": "메모, 이메일, 메시지, 프롬프트를 받아쓰고 어디든 붙여넣으세요.", "pills": ["이메일", "메모", "메시지"], "headline_size": 104},
            {"headline": "Whisper는 여기.\n당신의 말도 여기.", "supporting": "Mac에서 음성을 텍스트로. API 키와 오디오 업로드가 필요 없습니다.", "pills": ["키 불필요", "온디바이스", "CORE ML"], "headline_size": 100},
            {"headline": "내 키로.\n종속 없이.", "supporting": "Groq, OpenAI, Deepgram 또는 호환 서비스에 연결하세요.", "pills": ["GROQ", "OPENAI", "DEEPGRAM", "+ 더 보기"]},
            {"headline": "속도와 정확도.\n직접 선택하세요.", "supporting": "상황에 맞는 Whisper 모델과 언어를 선택하세요.", "pills": ["TINY", "BASE", "SMALL", "LARGE V3"], "headline_size": 102},
            {"headline": "좋은 생각을\n다시 놓치지 마세요.", "supporting": "선택적 로컬 기록에 저장하고 언제든 다시 복사하세요.", "pills": ["로컬 기록", "복사", "삭제"], "headline_size": 100},
            {"headline": "한 번 누르기.\n또는 누르고 말하기.", "supporting": "원하는 단축키로 자연스럽게 받아쓰세요.", "pills": ["⌥ 스페이스", "토글", "길게 누르기"], "headline_size": 98},
        ],
    },
    "zh-Hans": {
        "brand": "macOS WHISPER 听写",
        "screens": [
            {"headline": "你的想法，\n已经成文。", "supporting": "自然说话即可。灵感消失前，Vorb 已将语音变成文字。", "pills": ["语音 → 文字", "⌥ 空格", "随处粘贴"], "headline_size": 108},
            {"headline": "说出来。\n粘贴使用。", "supporting": "一个快捷键，就能把语音变成可在任何应用中粘贴的文字。", "pills": ["语音", "→", "文字"], "transcript_label": "转写文本", "transcript": "记得在午饭前发送最终稿。", "ready": "可粘贴", "headline_size": 108},
            {"headline": "一个声音，\n完成所有写作。", "supporting": "口述笔记、邮件、消息和提示词，然后粘贴到任何地方。", "pills": ["邮件", "笔记", "消息"], "headline_size": 106},
            {"headline": "Whisper 留在这里。\n你的话也一样。", "supporting": "在 Mac 本地语音转文字。无需 API 密钥，不上传音频。", "pills": ["无需密钥", "设备端", "CORE ML"], "headline_size": 100},
            {"headline": "你的密钥。\n没有锁定。", "supporting": "连接 Groq、OpenAI、Deepgram 或任何兼容服务。", "pills": ["GROQ", "OPENAI", "DEEPGRAM", "+ 更多"]},
            {"headline": "速度还是精度？\n由你决定。", "supporting": "选择适合当前需求的 Whisper 模型和语言。", "pills": ["TINY", "BASE", "SMALL", "LARGE V3"], "headline_size": 106},
            {"headline": "再也不错过\n任何好想法。", "supporting": "可选的本地历史记录，随时重新复制文本。", "pills": ["本地历史", "复制", "删除"], "headline_size": 106},
            {"headline": "按一下。\n或按住说话。", "supporting": "自定义全局快捷键，让语音输入更自然。", "pills": ["⌥ 空格", "切换", "按住"], "headline_size": 108},
        ],
    },
    "ru": {
        "brand": "WHISPER-ДИКТОВКА ДЛЯ macOS",
        "screens": [
            {"headline": "Ваши мысли.\nУже напечатаны.", "supporting": "Просто говорите. Vorb превратит голос в текст, пока идея не исчезла.", "pills": ["ГОЛОС → ТЕКСТ", "⌥ ПРОБЕЛ", "ВСТАВИТЬ ВЕЗДЕ"], "headline_size": 104},
            {"headline": "Скажите.\nВставьте.", "supporting": "Одно сочетание клавиш превращает голос в текст для любого приложения.", "pills": ["ГОЛОС", "→", "ТЕКСТ"], "transcript_label": "РАСПОЗНАННЫЙ ТЕКСТ", "transcript": "Не забудьте отправить финальную версию\nдо обеда.", "ready": "ГОТОВО К ВСТАВКЕ", "headline_size": 106},
            {"headline": "Один голос.\nДля любых текстов.", "supporting": "Диктуйте заметки, письма, сообщения и промпты, затем вставляйте куда угодно.", "pills": ["ПОЧТА", "ЗАМЕТКИ", "СООБЩЕНИЯ"], "headline_size": 104},
            {"headline": "Whisper остаётся здесь.\nВаши слова тоже.", "supporting": "Распознавание на Mac. Без API-ключа и загрузки аудио.", "pills": ["БЕЗ КЛЮЧА", "НА УСТРОЙСТВЕ", "CORE ML"], "headline_size": 92},
            {"headline": "Ваши ключи.\nНикакой привязки.", "supporting": "Подключите Groq, OpenAI, Deepgram или любой совместимый сервис.", "pills": ["GROQ", "OPENAI", "DEEPGRAM", "+ ЕЩЁ"], "headline_size": 104},
            {"headline": "Скорость или точность?\nРешаете вы.", "supporting": "Выберите подходящую модель Whisper и язык.", "pills": ["TINY", "BASE", "SMALL", "LARGE V3"], "headline_size": 96},
            {"headline": "Не теряйте\nхорошие идеи.", "supporting": "Сохраняйте необязательную локальную историю и копируйте текст снова.", "pills": ["ЛОКАЛЬНАЯ ИСТОРИЯ", "КОПИРОВАТЬ", "УДАЛИТЬ"], "headline_size": 104},
            {"headline": "Нажмите один раз.\nИли удерживайте.", "supporting": "Выберите сочетание клавиш и диктуйте естественно.", "pills": ["⌥ ПРОБЕЛ", "ПЕРЕКЛЮЧАТЬ", "УДЕРЖИВАТЬ"], "headline_size": 98},
        ],
    },
}

LOCALE_ORDER = [
    "en-US",
    "de-DE",
    "fr-FR",
    "es-ES",
    "pt-BR",
    "it",
    "ja",
    "ko",
    "zh-Hans",
    "ru",
]
