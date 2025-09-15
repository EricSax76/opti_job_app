import React, { useEffect } from "react";
import { Link } from "react-router-dom";
import "../styles/general.css";

const LandingPage = () => {
  useEffect(() => {
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const el = entry.target;
            el.classList.add("is-visible");

            // Stagger simple: aplica delays a hijos marcados
            if (el.dataset.stagger === "children") {
              const items = el.querySelectorAll(".stagger-item");
              items.forEach((child, idx) => {
                child.style.transitionDelay = `${100 + idx * 60}ms`;
              });
            }
            io.unobserve(el);
          }
        });
      },
      { rootMargin: "0px 0px -10% 0px", threshold: 0.15 }
    );

    document.querySelectorAll(".reveal").forEach((el) => io.observe(el));
    return () => io.disconnect();
  }, []);

  return (
    <div className="landing-container">
      {/* Navigation */}
      <nav className="landing-nav">
        <h1 className="logo">OPTIJOB</h1>
        <Link to="/CandidateLogin" className="btn btn-login">
          Inicia Sesión como Candidato
        </Link>
        <Link to="/job-offer" className="btn btn-login">
        Ofertas de Trabajo</Link>
        <Link to="/CompanyLogin" className="btn btn-login">
          Inicia Sesión como Empresa
        </Link>
      </nav>

      <main className="landing-main">
  {/* Optimización con IA */}
  <section className="section-optimization reveal fade-up" data-stagger="children">
    <h2>Optimización con IA</h2>
    <p>
      Nuestra aplicación utiliza algoritmos de inteligencia artificial avanzados para transformar el proceso de reclutamiento. Descubre cómo la tecnología puede facilitar tus objetivos:
    </p>
    <ul>
      <li className="stagger-item">📊 <strong>Analizar perfiles de candidatos:</strong> Procesamiento en segundos gracias a algoritmos inteligentes.</li>
      <li className="stagger-item">🤖 <strong>Automatizar programación:</strong> Agenda entrevistas con facilidad y precisión.</li>
      <li className="stagger-item">🔍 <strong>Identificar el mejor ajuste:</strong> Encuentra el talento ideal basado en datos concretos.</li>
    </ul>

  </section>

  {/* Beneficios para Empresas */}
  <section className="section-benefits reveal fade-up" data-stagger="children">
    <h2>Beneficios para Empresas</h2>
    <p>
      Acelera tu proceso de contratación con herramientas diseñadas para maximizar la eficiencia y garantizar resultados de calidad.
    </p>
    <div className="benefits-container">
      <div className="benefit stagger-item">
        <h3>🕒 Ahorro de Tiempo</h3>
        <p>Encuentra candidatos en minutos, no en días.</p>
        
      </div>
      <div className="benefit stagger-item">
        <h3>📈 Mejora del Proceso</h3>
        <p>Automatización que simplifica tu flujo de trabajo.</p>
        
      </div>
      <div className="benefit stagger-item">
        <h3>💡 Decisiones Inteligentes</h3>
        <p>Datos y análisis para elegir al mejor talento.</p>
        
      </div>
    </div>
  </section>

  {/* Beneficios para Candidatos */}
  <section className="section-candidates reveal fade-up" data-stagger="children">
    <h2>Beneficios para Candidatos</h2>
    <p>
      Encuentra tu próxima oportunidad con herramientas diseñadas para potenciar tu perfil profesional y conectar con las mejores empresas.
    </p>
    <ul>
      <li className="stagger-item">🎯 <strong>Ofertas personalizadas:</strong> Encuentra oportunidades ideales según tu experiencia y habilidades.</li>
      <li className="stagger-item">💼 <strong>Recomendaciones inteligentes:</strong> Mejora tus posibilidades de éxito con sugerencias basadas en IA.</li>
      <li className="stagger-item">⚡ <strong>Procesos rápidos:</strong> Reduce tiempos y elimina complicaciones innecesarias.</li>
    </ul>
    
  </section>

  {/* Cómo Funciona */}
  <section className="section-how-it-works reveal fade-up" data-stagger="children">
    <h2>¿Cómo Funciona?</h2>
    <p>
      Integramos tecnología de inteligencia artificial para ofrecer una experiencia fluida tanto para empresas como para candidatos. Sigue estos simples pasos:
    </p>
    <ol>
      <li className="stagger-item">🚀 <strong>Regístrate:</strong> Selecciona si eres una empresa o un candidato.</li>
      <li className="stagger-item">📥 <strong>Sube tus datos:</strong> Las empresas pueden publicar ofertas y los candidatos subir su información profesional.</li>
      <li className="stagger-item">🤝 <strong>Conexión:</strong> La IA empareja el mejor talento con las mejores oportunidades laborales.</li>
      <li className="stagger-item">📅 <strong>Gestión de entrevistas:</strong> Prográmate fácilmente con herramientas automatizadas.</li>
    </ol>
    <img
      src="https://via.placeholder.com/600x300"
      alt="Proceso de funcionamiento de la plataforma"
      className="section-image reveal fade-up"
    />
  </section>

        {/* Call to Action */}
        <div className="cta-buttons">
          <Link to="/companyregister" className="btn btn-register-empresa">
            Regístrate como Empresa
          </Link>
          <Link to="/candidateregister" className="btn btn-register-candidato">
            Regístrate como Candidato
          </Link>
        </div>
      </main>

      <footer className="landing-footer">
        <p>© 2025 Tu Empresa. Todos los derechos reservados.</p>
      </footer>
    </div>
  );
};

export default LandingPage;
