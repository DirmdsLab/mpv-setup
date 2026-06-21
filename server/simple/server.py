from flask import Flask, request, Response, jsonify
import subprocess
import time

app = Flask(__name__)


# ==========================================================
# API 0 - HEALTH
# ==========================================================
@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "ok"
    })

# ==========================================================
# TRANSLATE FUNCTION (dipakai semua endpoint)
# ==========================================================
def do_translate(text):
    result = subprocess.run(
        ["trans", "-b", "-s", "en", "-t", "id", text],
        capture_output=True,
        text=True
    )
    return result.stdout.strip()


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
    print(" MPV Subtitle Translate Server ")
    print("====================================")
    print("Listening on : http://0.0.0.0:5000")
    print("Endpoints:")
    print(" - /translate")
    print(" - /translate_sub")
    print(" - /health")
    print("====================================\n")

    app.run(host="0.0.0.0", port=5010, debug=False)
