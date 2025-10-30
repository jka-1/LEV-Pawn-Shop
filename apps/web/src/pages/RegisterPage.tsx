import PageTitle from '../components/PageTitle';
import Register from '../components/Register';

export default function RegisterPage() {
  return (
    <div className="page page--auth">
      <PageTitle />
      <Register />
      <p style={{ marginTop: 12 }}>
        Already have an account? <a href="/">Sign in</a>
      </p>
    </div>
  );
}
