import "../styles/components/CandidateCard.css";

const CandidateCard = ({ candidate }) => {
    return (
        <div className="candidate-card">
            <h3>{candidate.name}</h3>
            <p><strong>Skills:</strong> {candidate.skills.join(", ")}</p>
            <p><strong>Location:</strong> {candidate.location}</p>
        </div>
    );
};

export default CandidateCard;
