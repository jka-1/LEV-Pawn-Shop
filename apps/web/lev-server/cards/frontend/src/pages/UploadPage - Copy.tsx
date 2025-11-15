import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import NavBar from "../components/NavBar";
import UploadItem from "../components/UploadItem";

export default function UploadPage() {
  const navigate = useNavigate();

  useEffect(() => {
    try {
      const raw = localStorage.getItem("user_data");
      if (!raw) navigate("/"); // not logged in → go to login
    } catch {
      navigate("/");
    }
  }, [navigate]);

  return (
    <div className="page page--upload">
      <NavBar />
      <main className="container">
        <h2 className="page__title">Upload an Item for Appraisal</h2>
        <p className="page__subtitle">High-quality images lead to faster and better quotes.</p>
        <UploadItem />
      </main>
    </div>
  );
}
