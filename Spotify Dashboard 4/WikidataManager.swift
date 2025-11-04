//
//  WikidataManager.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import Foundation
import Combine

// MARK: - Wikidata Data Models

struct WikidataEntity: Codable {
    let id: String
    let labels: [String: LabelValue]?
    let descriptions: [String: LabelValue]?
    let claims: [String: [Claim]]?
    let sitelinks: [String: SiteLink]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case labels
        case descriptions
        case claims
        case sitelinks
    }
    
    var label: String? {
        return labels?["en"]?.value ?? labels?.values.first?.value
    }
    
    var description: String? {
        return descriptions?["en"]?.value ?? descriptions?.values.first?.value
    }
}

struct LabelValue: Codable {
    let value: String
    let language: String
}

struct Claim: Codable {
    let mainsnak: MainSnak?
    let qualifiers: [String: [Qualifier]]?
}

struct MainSnak: Codable {
    let datavalue: DataValue?
    let datatype: String?
    let property: String?
}

struct DataValue: Codable {
    let value: ValueContent?
    let type: String?
}

struct ValueContent: Codable {
    let id: String?
    let time: String?
    let amount: String?
    let text: String?
    let entityType: String?
    
    enum CodingKeys: String, CodingKey {
        case id, time, amount, text
        case entityType = "entity-type"
    }
}

struct Qualifier: Codable {
    let datavalue: DataValue?
    let property: String?
}

struct SiteLink: Codable {
    let site: String
    let title: String
    let badges: [String]?
}

struct WikidataEntityData: Codable {
    let entities: [String: WikidataEntity]
}

// MARK: - SPARQL Response Models

struct SPARQLResponse: Codable {
    let results: SPARQLResults?
    let head: SPARQLHead?
}

struct SPARQLResults: Codable {
    let bindings: [SPARQLBinding]
}

struct SPARQLBinding: Codable {
    let author: SPARQLValue?
    let authorLabel: SPARQLValue?
    let description: SPARQLValue?
    let work: SPARQLValue?
    let workLabel: SPARQLValue?
    let birthDate: SPARQLValue?
    let deathDate: SPARQLValue?
    let occupation: SPARQLValue?
    let occupationLabel: SPARQLValue?
    let image: SPARQLValue?
    
    enum CodingKeys: String, CodingKey {
        case author
        case authorLabel
        case description
        case work
        case workLabel
        case birthDate
        case deathDate
        case occupation
        case occupationLabel
        case image
    }
}

struct SPARQLValue: Codable {
    let type: String
    let value: String
    let datatype: String?
    let xmlLang: String?
    
    enum CodingKeys: String, CodingKey {
        case type, value, datatype
        case xmlLang = "xml:lang"
    }
}

struct SPARQLHead: Codable {
    let vars: [String]
}

// MARK: - Wikidata Author Info

struct WikidataAuthorInfo: Codable {
    let entityId: String
    let name: String
    let description: String?
    let biography: String?
    let birthDate: String?
    let deathDate: String?
    let occupations: [String]
    let works: [WikidataWork]
    let imageURL: String?
    
    init(entityId: String, name: String, description: String? = nil, biography: String? = nil, birthDate: String? = nil, deathDate: String? = nil, occupations: [String] = [], works: [WikidataWork] = [], imageURL: String? = nil) {
        self.entityId = entityId
        self.name = name
        self.description = description
        self.biography = biography
        self.birthDate = birthDate
        self.deathDate = deathDate
        self.occupations = occupations
        self.works = works
        self.imageURL = imageURL
    }
}

struct WikidataWork: Codable, Identifiable {
    let id: String
    let title: String
    let entityId: String?
    
    init(id: String, title: String, entityId: String? = nil) {
        self.id = id
        self.title = title
        self.entityId = entityId
    }
}

// MARK: - Wikidata Manager

class WikidataManager: ObservableObject {
    @Published var authorInfo: [String: WikidataAuthorInfo] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let sparqlEndpoint = "https://query.wikidata.org/sparql"
    private let entityDataEndpoint = "https://www.wikidata.org/wiki/Special:EntityData"
    
    // MARK: - Find Author Entity ID
    
    func findAuthorEntityId(authorName: String) async -> String? {
        // Check cache first for faster response
        if let cachedInfo = authorInfo.values.first(where: { $0.name.lowercased() == authorName.lowercased() }) {
            print("📦 Found cached Wikidata entity ID: \(cachedInfo.entityId)")
            return cachedInfo.entityId
        }
        
        print("🔍 Searching Wikidata for author: '\(authorName)'")
        
        let query = """
        SELECT DISTINCT ?author ?authorLabel WHERE {
          ?author wdt:P31 wd:Q5.
          ?author rdfs:label ?authorLabel.
          FILTER(LANG(?authorLabel) = "en")
          FILTER(CONTAINS(LCASE(?authorLabel), LCASE("\(authorName)")))
        }
        LIMIT 1
        """
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(sparqlEndpoint)?query=\(encodedQuery)&format=json") else {
            print("❌ Invalid Wikidata query URL")
            return nil
        }
        
        do {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Music Story Companion/1.0", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 10.0 // 10 second timeout for faster failure
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode else {
                print("❌ Wikidata HTTP error: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return nil
            }
            
            let sparqlResponse = try JSONDecoder().decode(SPARQLResponse.self, from: data)
            
            if let binding = sparqlResponse.results?.bindings.first,
               let authorValue = binding.author?.value {
                let entityId = authorValue.components(separatedBy: "/").last ?? authorValue
                print("✅ Found Wikidata entity ID: \(entityId) for \(authorName)")
                return entityId
            }
            
            print("⚠️ No Wikidata entity found for: \(authorName)")
            return nil
            
        } catch {
            print("❌ Wikidata search error: \(error)")
            return nil
        }
    }
    
    // MARK: - Get Author Info via SPARQL
    
    func getAuthorInfo(authorName: String) async -> WikidataAuthorInfo? {
        // First, try to find the entity ID
        guard let entityId = await findAuthorEntityId(authorName: authorName) else {
            print("⚠️ Could not find Wikidata entity for: \(authorName)")
            return nil
        }
        
        // Check cache
        if let cachedInfo = authorInfo[entityId] {
            print("📦 Using cached Wikidata info for: \(authorName)")
            return cachedInfo
        }
        
        print("📚 Fetching detailed Wikidata info for: \(authorName) (ID: \(entityId))")
        
        let query = """
        SELECT ?author ?authorLabel ?description ?work ?workLabel ?birthDate ?deathDate ?occupation ?occupationLabel ?image WHERE {
          BIND(wd:\(entityId) AS ?author)
          
          ?author rdfs:label ?authorLabel.
          FILTER(LANG(?authorLabel) = "en")
          
          OPTIONAL {
            ?author schema:description ?description.
            FILTER(LANG(?description) = "en")
          }
          
          OPTIONAL {
            ?author wdt:P569 ?birthDate.
          }
          
          OPTIONAL {
            ?author wdt:P570 ?deathDate.
          }
          
          OPTIONAL {
            ?author wdt:P106 ?occupation.
            ?occupation rdfs:label ?occupationLabel.
            FILTER(LANG(?occupationLabel) = "en")
          }
          
          OPTIONAL {
            ?work wdt:P50 ?author.
            ?work rdfs:label ?workLabel.
            FILTER(LANG(?workLabel) = "en")
          }
          
          OPTIONAL {
            ?author wdt:P18 ?image.
          }
          
          SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
        }
        LIMIT 50
        """
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(sparqlEndpoint)?query=\(encodedQuery)&format=json") else {
            print("❌ Invalid Wikidata SPARQL URL")
            return nil
        }
        
        do {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Music Story Companion/1.0", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 15.0 // 15 second timeout for detailed queries
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode else {
                print("❌ Wikidata HTTP error: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return nil
            }
            
            let sparqlResponse = try JSONDecoder().decode(SPARQLResponse.self, from: data)
            
            // Parse SPARQL results
            var authorName: String?
            var description: String?
            var birthDate: String?
            var deathDate: String?
            var occupations: Set<String> = []
            var works: [WikidataWork] = []
            var imageURL: String?
            
            for binding in sparqlResponse.results?.bindings ?? [] {
                if authorName == nil, let name = binding.authorLabel?.value {
                    authorName = name
                }
                
                if description == nil, let desc = binding.description?.value {
                    description = desc
                }
                
                if birthDate == nil, let bDate = binding.birthDate?.value {
                    // Parse Wikidata date format (e.g., +1835-11-30T00:00:00Z)
                    birthDate = formatWikidataDate(bDate)
                }
                
                if deathDate == nil, let dDate = binding.deathDate?.value {
                    deathDate = formatWikidataDate(dDate)
                }
                
                if let occupation = binding.occupationLabel?.value {
                    occupations.insert(occupation)
                }
                
                if let workTitle = binding.workLabel?.value,
                   let workValue = binding.work?.value {
                    let workId = workValue.components(separatedBy: "/").last ?? ""
                    // Avoid duplicates
                    if !workId.isEmpty && !works.contains(where: { $0.title == workTitle }) {
                        works.append(WikidataWork(id: workId, title: workTitle, entityId: workId))
                    }
                }
                
                if imageURL == nil, let img = binding.image?.value {
                    imageURL = img
                }
            }
            
            guard let name = authorName else {
                print("❌ No author name found in Wikidata response")
                return nil
            }
            
            // Get full biography from entity data
            let biography = await getFullBiography(entityId: entityId)
            
            let authorInfo = WikidataAuthorInfo(
                entityId: entityId,
                name: name,
                description: description,
                biography: biography ?? description,
                birthDate: birthDate,
                deathDate: deathDate,
                occupations: Array(occupations),
                works: Array(works.prefix(20)), // Limit to 20 works
                imageURL: imageURL
            )
            
            // Cache the result
            await MainActor.run {
                self.authorInfo[entityId] = authorInfo
            }
            
            print("✅ Loaded Wikidata info for: \(name)")
            if let bio = authorInfo.biography, !bio.isEmpty {
                print("📖 Biography length: \(bio.count) characters")
            }
            
            return authorInfo
            
        } catch {
            print("❌ Wikidata SPARQL error: \(error)")
            return nil
        }
    }
    
    // MARK: - Get Full Biography from Entity Data
    
    private func getFullBiography(entityId: String) async -> String? {
        guard let url = URL(string: "\(entityDataEndpoint)/\(entityId).json") else {
            return nil
        }
        
        do {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Music Story Companion/1.0", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 15.0 // 15 second timeout for detailed queries
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode else {
                return nil
            }
            
            let entityData = try JSONDecoder().decode(WikidataEntityData.self, from: data)
            
            guard let entity = entityData.entities[entityId] else {
                return nil
            }
            
            // Get description as biography
            if let desc = entity.description, !desc.isEmpty {
                return desc
            }
            
            // Try to get from claims (P569 = birth date, P570 = death date, P735 = given name, P1559 = name in native language)
            // Build a basic biography from available data
            var bioParts: [String] = []
            
            if let label = entity.label {
                bioParts.append("\(label) is")
            }
            
            // Try to get occupation
            if let claims = entity.claims {
                // P106 = occupation
                if let occupationClaims = claims["P106"] {
                    let occupations = occupationClaims.compactMap { claim -> String? in
                        guard let entityId = claim.mainsnak?.datavalue?.value?.id,
                              let entity = entityData.entities[entityId] else {
                            return nil
                        }
                        return entity.label
                    }
                    if !occupations.isEmpty {
                        bioParts.append("a \(occupations.joined(separator: " and "))")
                    }
                }
            }
            
            return bioParts.isEmpty ? nil : bioParts.joined(separator: " ")
            
        } catch {
            print("❌ Error fetching Wikidata entity data: \(error)")
            return nil
        }
    }
    
    // MARK: - Format Wikidata Date
    
    private func formatWikidataDate(_ dateString: String) -> String {
        // Wikidata date format: +1835-11-30T00:00:00Z
        // Extract year-month-day
        let pattern = #"\+\d{4}-\d{2}-\d{2}"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: dateString, range: NSRange(dateString.startIndex..., in: dateString)),
           let range = Range(match.range, in: dateString) {
            let datePart = String(dateString[range])
            // Remove + and format as YYYY-MM-DD, then parse to readable format
            let cleanDate = String(datePart.dropFirst())
            let components = cleanDate.components(separatedBy: "-")
            if components.count == 3 {
                // Format as "Month Day, Year" or "YYYY-MM-DD"
                return "\(components[1])/\(components[2])/\(components[0])" // MM/DD/YYYY
            }
        }
        return dateString
    }
    
    // MARK: - Batch Fetch Author Info
    
    func fetchAuthorInfoBatch(authorNames: [String]) async {
        print("📚 Fetching Wikidata info for \(authorNames.count) authors...")
        
        await withTaskGroup(of: (String, WikidataAuthorInfo?).self) { group in
            for authorName in authorNames {
                group.addTask {
                    let info = await self.getAuthorInfo(authorName: authorName)
                    return (authorName, info)
                }
            }
            
            var fetchedCount = 0
            for await (authorName, info) in group {
                if info != nil {
                    fetchedCount += 1
                    print("✅ Wikidata info fetched for: \(authorName)")
                } else {
                    print("⚠️ No Wikidata info for: \(authorName)")
                }
            }
            
            print("📊 Wikidata batch complete: \(fetchedCount)/\(authorNames.count) authors")
        }
    }
}

