// FilterForm.js
import { useState } from 'react';
import "../styles/components/FilterForm.css";

const FilterForm = ({ onFilter }) => {
    const [keywords, setKeywords] = useState("");
    const [location, setLocation] = useState("");

    const handleSubmit = (e) => {
        e.preventDefault();
        onFilter({ keywords, location });
    };

    return (
        <form className="filter-form" onSubmit={handleSubmit}>
            <input
                type="text"
                placeholder="Keywords"
                value={keywords}
                onChange={(e) => setKeywords(e.target.value)}
            />
            <input
                type="text"
                placeholder="Location"
                value={location}
                onChange={(e) => setLocation(e.target.value)}
            />
            <button type="submit">Filter</button>
        </form>
    );
};

export default FilterForm;
