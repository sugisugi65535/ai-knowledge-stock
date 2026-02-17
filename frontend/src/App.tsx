import { useMemo, useState } from "react";

type HealthzResponse = {
  healthz: "success" | "fail";
};

function requireEnv(name: "BACK_BASE_URL" | "BACK_BASE_PORT"): string {
  const value = import.meta.env[name];
  if (typeof value !== "string" || value.trim() === "") {
    throw new Error(`必須環境変数が未設定です: ${name}`);
  }
  return value;
}

export default function App() {
  const [result, setResult] = useState<string>("未実行");
  const [isLoading, setIsLoading] = useState<boolean>(false);

  const backendHealthzUrl = useMemo(() => {
    const backBaseUrl = requireEnv("BACK_BASE_URL");
    const backBasePort = requireEnv("BACK_BASE_PORT");
    return `http://${backBaseUrl}:${backBasePort}/api/healthz`;
  }, []);

  const onClickAccessBackend = async () => {
    setIsLoading(true);
    setResult("通信中...");
    try {
      const response = await fetch(backendHealthzUrl, { method: "GET" });
      const body = (await response.json()) as HealthzResponse;
      setResult(JSON.stringify(body));
    } catch (_error) {
      setResult(JSON.stringify({ healthz: "fail" }));
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <main className="page">
      <h1>サンプルトップページ（ユーザ画面）</h1>
      <div className="lower-center">
        <button onClick={onClickAccessBackend} disabled={isLoading}>
          バックエンドへアクセス
        </button>
        <p>{result}</p>
      </div>
    </main>
  );
}
