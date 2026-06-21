from flask import Flask, request, Response, jsonify
import requests
import json
import time

app = Flask(__name__)

LLM_URL = "http://localhost:8080/v1/chat/completions"


# ==========================================================
# API 0 - HEALTH
# ==========================================================
@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "ok"
    })

# ==========================================================
# API - CURRENT TITLE FROM MPV
# ==========================================================
@app.route("/title", methods=["POST"])
def current_title():

    data = request.get_json(silent=True) or {}

    title = data.get("title", "")

    print("\n" + "=" * 60)
    print("NOW PLAYING")
    print("=" * 60)
    print(title)
    print("=" * 60 + "\n", flush=True)

    return jsonify({
        "ok": True,
        "title": title
    })

# ==========================================================
# TRANSLATE FUNCTION (AI)
# ==========================================================
def do_translate(text):

    payload = {
        "temperature": 0,
        "top_p": 0.1,
        "response_format": {
            "type": "json_object"
        },
        "messages": [
            {
                "role": "system",
                "content": """
You are an English to Indonesian translator.

Return ONLY valid JSON.

{
  "original": "string",
  "translated": "string"
}
"""
            },
            {
                "role": "user",
                "content": text
            }
        ]
    }

    try:
        response = requests.post(
            LLM_URL,
            json=payload,
            timeout=120
        )

        response.raise_for_status()

        data = response.json()

        content = data["choices"][0]["message"]["content"]

        result = json.loads(content)

        return result["translated"]

    except Exception as e:
        print("TRANSLATE ERROR:", e)
        return text


# ==========================================================
# BUILD VTT
# ==========================================================
def build_vtt(subs):

    output = ["WEBVTT\n"]
    total = len(subs)

    print("\n====================================")
    print(f"TRANSLATE START  |  {total} lines")
    print("====================================")

    start_time = time.time()

    for i, line in enumerate(subs, start=1):

        text = line["text"]
        timecode = line["time"].replace(",", ".")

        print(f"[{i}/{total}] Translating:")
        print("TEXT:", text)

        translated = do_translate(text)

        print("RESULT:", translated)
        print("------------------------------------")

        output.append(str(i))
        output.append(timecode)
        output.append(translated)
        output.append("")

    end_time = time.time()

    print("====================================")
    print("TRANSLATE FINISHED")
    print(f"Total lines : {total}")
    print(f"Time taken  : {round(end_time-start_time,2)} sec")
    print("====================================\n")

    return "\n".join(output)


# ==========================================================
# API 1 - SINGLE TEXT
# ==========================================================
@app.route("/translate", methods=["POST"])
def translate_api():

    data = request.json
    text = data.get("text", "")

    if not text:
        return jsonify({"error": "No text"}), 400

    translated = do_translate(text)

    return jsonify({
        "original": text,
        "translated": translated
    })


# ==========================================================
# API 2 - SUBTITLE
# ==========================================================
@app.route("/translate_sub", methods=["POST"])
def translate_sub():

    data = request.json

    if not data or "subs" not in data:
        return jsonify({"error": "Invalid data"}), 400

    subs = data["subs"]
    vtt = build_vtt(subs)

    return Response(vtt, mimetype="text/vtt")




# ==========================================================
# MAIN
# ==========================================================
if __name__ == "__main__":

    print("\n====================================")
    print(" MPV AI Subtitle Translate Server ")
    print("====================================")
    print("LLM :", LLM_URL)
    print("Listening on : http://0.0.0.0:5010")
    print("Endpoints:")
    print(" - /translate")
    print(" - /translate_sub")
    print(" - /health")
    print("====================================\n")
    
    app.run(host="0.0.0.0", port=5010, debug=False)