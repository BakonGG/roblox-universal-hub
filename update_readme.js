const fs = require('fs');
const path = require('path');

const gamesDir = path.join(__dirname, 'games');
const readmePath = path.join(__dirname, 'README.md');

async function fetchGameName(id) {
    try {
        const uniRes = await fetch(`https://apis.roblox.com/universes/v1/places/${id}/universe`);
        if (!uniRes.ok) return `Game ${id} (Unknown Name)`;
        const uniData = await uniRes.json();
        const universeId = uniData.universeId;
        
        if (!universeId) return `Game ${id} (Unknown Name)`;
        
        const gameRes = await fetch(`https://games.roblox.com/v1/games?universeIds=${universeId}`);
        if (!gameRes.ok) return `Game ${id} (Unknown Name)`;
        const gameData = await gameRes.json();
        
        if (gameData && gameData.data && gameData.data.length > 0) {
            return gameData.data[0].name;
        }
        return `Game ${id} (Unknown Name)`;
    } catch (err) {
        return `Game ${id} (Unknown Name)`;
    }
}

async function updateReadme() {
    console.log("Lendo a pasta 'games'...");
    const files = fs.readdirSync(gamesDir);
    
    let markdownList = ``;
    
    const gamePromises = files
        .filter(file => file.endsWith('.lua'))
        .map(async (file) => {
            const id = file.replace('.lua', '');
            if (isNaN(id)) return null; // Ignora default.lua etc
            
            console.log(`Buscando nome para o ID: ${id}...`);
            const name = await fetchGameName(id);
            return `- [${name}](https://www.roblox.com/games/${id}) \`(${id})\``;
        });
        
    const results = await Promise.all(gamePromises);
    
    const validResults = results.filter(r => r !== null);
    
    const readmeContent = `# Roblox Universal Hub\n\nHub Universal de scripts para Roblox.\n\n## 🎮 Jogos Suportados\n\nAtualmente temos scripts prontos para os seguintes jogos:\n\n${validResults.join('\n')}\n\n---\n*Gerado automaticamente pelo script \`update_readme.js\`*`;
    
    fs.writeFileSync(readmePath, readmeContent, 'utf-8');
    console.log("README.md atualizado com sucesso com todos os jogos!");
}

updateReadme();
