import Foundation

/// Seed content for the demo: five providers, the client's own bookings and the
/// specialist's working day.
nonisolated enum SampleData {
    static let clientName = "Ieva Kazlauskaitė"
    static let specialistName = "Kipras Morkūnas"
    static let homeVenue = "Studio Noma"

    /// The salon's client base. One record per person, reused by the client list,
    /// the calendar search and appointment details.
    static let clientDirectory: [Client] = [
        client("A0000001", "Ieva", "Kazlauskaitė", "+370 612 34 507", since: -430),
        client("A0000002", "Lina", "Petrauskaitė", "+370 674 11 220", since: -520),
        client("A0000003", "Rūta", "Balčiūnė", "+370 655 90 134", since: -180),
        client("A0000004", "Tomas", "Žukauskas", "+370 601 47 762", since: -260),
        client("A0000005", "Kipras", "Adomaitis", "+370 686 22 948", since: -610),
        client("A0000006", "Justina", "Rimšaitė", "+370 699 30 415", since: -300),
        client("A0000007", "Mantas", "Sereika", "+370 638 55 903", since: -240),
        client("A0000008", "Grėtė", "Milaitė", "+370 645 78 331", since: -150),
        client("A0000009", "Arūnas", "Petkus", "+370 622 19 604", since: -200),
        client("A0000010", "Domas", "Jankus", "+370 608 44 275", since: -95)
    ]

    static func phone(for name: String) -> String {
        clientDirectory.first { $0.fullName == name }?.phone ?? ""
    }

    static func clientID(for name: String) -> UUID? {
        clientDirectory.first { $0.fullName == name }?.id
    }

    private static func client(
        _ seed: String,
        _ firstName: String,
        _ lastName: String,
        _ phone: String,
        since dayOffset: Int
    ) -> Client {
        Client(
            id: UUID(uuidString: "\(seed)-0000-4000-8000-000000000000") ?? UUID(),
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            createdAt: AppDate.time(10, 0, dayOffset: dayOffset)
        )
    }

    /// Specialists sharing the salon floor.
    ///
    /// The same four people are the columns of the team calendar and the choice a client
    /// makes before picking a time. What each of them is allowed to perform is declared
    /// here, so the client never sees a master who cannot do the service they chose.
    static let team: [TeamMember] = [
        TeamMember(
            name: specialistName,
            craft: "Kirpėjas",
            isCurrentUser: true,
            providerID: studioNomaID,
            serviceNames: ["Kirpimas ir sušukavimas", "Kirpimas", "Barzdos tvarkymas"],
            rating: 4.9,
            reviewCount: 186,
            yearsExperience: 11,
            bio: "Dirbu su forma ir tekstūra. Niekada nenukerpu daugiau, nei sutarėme."
        ),
        TeamMember(
            name: "Adas Jasiūnas",
            craft: "Barberis",
            providerID: studioNomaID,
            serviceNames: ["Kirpimas", "Barzdos tvarkymas"],
            rating: 4.8,
            reviewCount: 124,
            yearsExperience: 6,
            bio: "Klasikiniai vyriški kirpimai, tikslūs kontūrai ir barzdos linija."
        ),
        TeamMember(
            name: "Rokas Abromavičius",
            craft: "Barberis",
            providerID: studioNomaID,
            serviceNames: ["Kirpimas", "Barzdos tvarkymas"],
            rating: 4.7,
            reviewCount: 68,
            yearsExperience: 3,
            bio: "Fade, mašinėlės darbai ir greitas kasdienis atnaujinimas."
        ),
        TeamMember(
            name: "Emilis Zupka",
            craft: "Koloristas",
            providerID: studioNomaID,
            serviceNames: ["Kirpimas ir sušukavimas"],
            rating: 5.0,
            reviewCount: 92,
            yearsExperience: 8,
            bio: "Spalva ir ilgi plaukai. Konsultacija visada prieš pirmą dažymą."
        )
    ]

    /// Personal block presets shown next to the standard ones.
    static let personalBlockPresets: [PersonalBlockPreset] = [
        PersonalBlockPreset(title: "Maistas", minutes: 30, symbolName: "fork.knife"),
        PersonalBlockPreset(title: "Sportas", minutes: 60, symbolName: "figure.run"),
        PersonalBlockPreset(title: "Pertrauka", minutes: 30, symbolName: "cup.and.saucer")
    ]

    /// Colleague appointments live under a floor id that is not a marketplace
    /// provider, so client-side availability stays untouched.
    private static let salonFloorID = UUID(uuidString: "99999999-9999-4999-8999-999999999999") ?? UUID()

    /// The weekly schedule most of the demo catalogue keeps.
    static func weekdayHours(open: Int, close: Int, saturday: (Int, Int)? = nil) -> [OpeningHours] {
        var hours = (1...5).map { OpeningHours(weekday: $0, from: open, to: close) }
        if let saturday {
            hours.append(OpeningHours(weekday: 6, from: saturday.0, to: saturday.1))
        } else {
            hours.append(.closed(weekday: 6))
        }
        hours.append(.closed(weekday: 7))
        return hours
    }

    /// The home venue's id, declared separately so the team can reference it before
    /// the provider itself is built.
    static let studioNomaID = UUID(uuidString: "11111111-1111-4111-8111-111111111111") ?? UUID()

    static let studioNoma = Provider(
        id: studioNomaID,
        name: "Studio Noma",
        specialistName: "Kipras Morkūnas",
        craft: "Kirpėjas",
        category: .hair,
        district: "Senamiestis",
        location: BusinessAddress(
            street: "Gedimino pr. 18",
            city: "Vilnius",
            latitude: 54.6889,
            longitude: 25.2749
        ),
        rating: 4.9,
        visitCount: 214,
        imageName: "boutique_hair_studio",
        about: "Rami studija su viena kėde, natūralia šviesa ir daug laiko konsultacijai. Kipras dirba su forma, tekstūra ir kasdieniu stilingu, kurį lengva pakartoti namuose.",
        services: [
            ServiceOffering(name: "Kirpimas ir sušukavimas", durationMinutes: 60, price: 65, detail: "Konsultacija, kirpimas, sušukavimas"),
            ServiceOffering(name: "Kirpimas", durationMinutes: 45, price: 45, detail: "Formos atnaujinimas"),
            ServiceOffering(name: "Barzdos tvarkymas", durationMinutes: 30, price: 25, detail: "Kontūrai ir priežiūra")
        ],
        nextSlot: AppDate.time(16, 30, dayOffset: 1),
        reviewCount: 312,
        phone: "+370 612 00 118",
        photoNames: ["boutique_hair_studio", "vintage_barber_chair_interior", "woman_blunt_layers_cut"],
        openingHours: weekdayHours(open: 9, close: 19, saturday: (10, 16))
    )

    static let noorSkinStudio = Provider(
        id: UUID(uuidString: "22222222-2222-4222-8222-222222222222") ?? UUID(),
        name: "Noor Skin Studio",
        specialistName: "Noor Rahman",
        craft: "Kosmetologė",
        category: .beauty,
        district: "Naujamiestis",
        location: BusinessAddress(
            street: "Švitrigailos g. 11",
            city: "Vilnius",
            latitude: 54.6795,
            longitude: 25.2622
        ),
        rating: 4.9,
        visitCount: 128,
        imageName: "spa_treatment_room",
        about: "Veido procedūros be skubos: konsultacija, giluminė priežiūra ir aiškus namų ritualas po vizito.",
        services: [
            ServiceOffering(name: "Atstatomoji procedūra", durationMinutes: 60, price: 120, detail: "Gilus drėkinimas ir masažas"),
            ServiceOffering(name: "Giluminis drėkinimas", durationMinutes: 45, price: 90, detail: "Jautriai odai"),
            ServiceOffering(name: "Greitas švytėjimas", durationMinutes: 30, price: 65, detail: "Prieš šventę ar susitikimą")
        ],
        nextSlot: AppDate.time(16, 15),
        reviewCount: 186,
        phone: "+370 640 55 210",
        photoNames: ["spa_treatment_room", "boutique_hair_studio"],
        openingHours: weekdayHours(open: 10, close: 20)
    )

    static let commonThread = Provider(
        id: UUID(uuidString: "33333333-3333-4333-8333-333333333333") ?? UUID(),
        name: "Common Thread Pilates",
        specialistName: "Rasa Vaitkė",
        craft: "Pilateso trenerė",
        category: .fitness,
        district: "Žvėrynas",
        location: BusinessAddress(
            street: "Vytauto g. 7",
            city: "Vilnius",
            latitude: 54.6912,
            longitude: 25.2531
        ),
        rating: 4.8,
        visitCount: 86,
        imageName: "pilates_studio_interior",
        about: "Individualios treniruotės ant reformerio. Programa pritaikoma pagal savijautą ir ankstesnių treniruočių istoriją.",
        services: [
            ServiceOffering(name: "Individuali treniruotė", durationMinutes: 55, price: 55, detail: "Vienas žmogus, visas dėmesys"),
            ServiceOffering(name: "Treniruotė dviese", durationMinutes: 55, price: 75, detail: "Su draugu ar antrąja puse")
        ],
        nextSlot: AppDate.time(8, 0, dayOffset: 1),
        reviewCount: 94,
        phone: "+370 699 12 044",
        photoNames: ["pilates_studio_interior"],
        openingHours: weekdayHours(open: 7, close: 21, saturday: (9, 14))
    )

    static let petalStem = Provider(
        id: UUID(uuidString: "44444444-4444-4444-8444-444444444444") ?? UUID(),
        name: "Petal & Stem",
        specialistName: "Gabija Lukošiūtė",
        craft: "Floristė",
        category: .home,
        district: "Senamiestis",
        location: BusinessAddress(
            street: "Pilies g. 24",
            city: "Vilnius",
            latitude: 54.6812,
            longitude: 25.2896
        ),
        rating: 4.9,
        visitCount: 61,
        imageName: "florist_workshop_roses",
        about: "Gėlių dirbtuvės, kuriose puokštė kuriama kartu su tavimi — pagal progą, spalvas ir sezoną.",
        services: [
            ServiceOffering(name: "Puokštės kūrimas", durationMinutes: 45, price: 48, detail: "Sezoninės gėlės"),
            ServiceOffering(name: "Dirbtuvės dviem", durationMinutes: 90, price: 95, detail: "Kūrybinis vakaras")
        ],
        nextSlot: AppDate.time(11, 0, dayOffset: 3),
        reviewCount: 57,
        phone: "+370 655 71 300",
        photoNames: ["florist_workshop_roses"],
        openingHours: weekdayHours(open: 10, close: 19, saturday: (10, 15))
    )

    static let formaHair = Provider(
        id: UUID(uuidString: "55555555-5555-4555-8555-555555555555") ?? UUID(),
        name: "Forma Hair Studio",
        specialistName: "Tadas Norvilas",
        craft: "Barberis",
        category: .hair,
        district: "Užupis",
        location: BusinessAddress(
            street: "Užupio g. 3",
            city: "Vilnius",
            latitude: 54.6829,
            longitude: 25.2938
        ),
        rating: 4.7,
        visitCount: 143,
        imageName: "vintage_barber_chair_interior",
        about: "Klasikinis barberio darbas su šiuolaikine forma: fade, barzda ir priežiūros patarimai kasdienai.",
        services: [
            ServiceOffering(name: "Vyriškas kirpimas", durationMinutes: 40, price: 32, detail: "Fade arba klasika"),
            ServiceOffering(name: "Kirpimas ir barzda", durationMinutes: 60, price: 45, detail: "Pilnas atnaujinimas")
        ],
        nextSlot: AppDate.time(18, 0),
        reviewCount: 241,
        phone: "+370 677 84 512",
        photoNames: ["vintage_barber_chair_interior", "mid_fade_haircut_profile", "low_fade_haircut"],
        openingHours: weekdayHours(open: 9, close: 20, saturday: (9, 15))
    )

    // MARK: - Other industries
    //
    // BookMeUp is a service platform, not a beauty directory. These exist so discovery,
    // the assistant and the category filters are exercised across real industries — a
    // client can ask for a dentist and actually get one.

    static let lakuKambarys = Provider(
        id: UUID(uuidString: "66666666-6666-4666-8666-666666666666") ?? UUID(),
        name: "Lakų Kambarys",
        specialistName: "Aistė Rudėnaitė",
        craft: "Manikiūrininke",
        category: .nails,
        district: "Naujamiestis",
        location: BusinessAddress(
            street: "Vilės g. 4",
            city: "Vilnius",
            latitude: 54.6841,
            longitude: 25.2603
        ),
        rating: 4.8,
        visitCount: 176,
        imageName: "boutique_hair_studio",
        about: "Ramus kambarys su vienu stalu. Daug dėmesio nagų sveikatai ir tam, kad danga išlaikytų.",
        services: [
            ServiceOffering(name: "Manikiūras su danga", durationMinutes: 75, price: 38, detail: "Higieninis manikiūras ir danga"),
            ServiceOffering(name: "Manikiūras", durationMinutes: 45, price: 26, detail: "Be dangos"),
            ServiceOffering(name: "Pedikiūras", durationMinutes: 60, price: 42, detail: "Higieninis pedikiūras")
        ],
        nextSlot: AppDate.time(12, 30),
        reviewCount: 203,
        phone: "+370 633 90 771",
        photoNames: ["boutique_hair_studio"],
        openingHours: weekdayHours(open: 9, close: 18, saturday: (10, 15))
    )

    static let tylu = Provider(
        id: UUID(uuidString: "66666666-7777-4777-8777-777777777777") ?? UUID(),
        name: "Tylu",
        specialistName: "Mindaugas Sakalas",
        craft: "Masažuotojas",
        category: .massage,
        district: "Žvėrynas",
        location: BusinessAddress(
            street: "Birutės g. 22",
            city: "Vilnius",
            latitude: 54.6903,
            longitude: 25.2470
        ),
        rating: 4.9,
        visitCount: 132,
        imageName: "spa_treatment_room",
        about: "Gydomasis ir atpalaiduojantis masažas tyliame kabinete. Prieš pirmą vizitą — trumpa konsultacija.",
        services: [
            ServiceOffering(name: "Atpalaiduojantis masažas", durationMinutes: 60, price: 45, detail: "Visas kūnas"),
            ServiceOffering(name: "Nugaros masažas", durationMinutes: 40, price: 35, detail: "Nugara ir pečiai"),
            ServiceOffering(name: "Gydomasis masažas", durationMinutes: 90, price: 70, detail: "Su konsultacija")
        ],
        nextSlot: AppDate.time(17, 0),
        reviewCount: 148,
        phone: "+370 611 47 908",
        photoNames: ["spa_treatment_room"],
        openingHours: weekdayHours(open: 10, close: 20, saturday: (10, 16))
    )

    static let dantuNamai = Provider(
        id: UUID(uuidString: "66666666-8888-4888-8888-888888888888") ?? UUID(),
        name: "Dantų Namai",
        specialistName: "Eglė Vasiliauskienė",
        craft: "Odontologė",
        category: .wellness,
        district: "Naujamiestis",
        location: BusinessAddress(
            street: "Geštauto g. 9",
            city: "Vilnius",
            latitude: 54.6884,
            longitude: 25.2695
        ),
        rating: 4.7,
        visitCount: 402,
        imageName: "spa_treatment_room",
        about: "Šeimos odontologija: profilaktika, higiena ir gydymas be skubos.",
        services: [
            ServiceOffering(name: "Profilaktinė konsultacija", durationMinutes: 30, price: 35, detail: "Apžiūra ir gydymo planas"),
            ServiceOffering(name: "Burnos higiena", durationMinutes: 60, price: 75, detail: "Profesionalus valymas")
        ],
        nextSlot: AppDate.time(9, 30, dayOffset: 2),
        reviewCount: 389,
        phone: "+370 521 44 830",
        photoNames: ["spa_treatment_room"],
        openingHours: weekdayHours(open: 8, close: 17)
    )

    /// The development example of a business registered outside the capital.
    ///
    /// Deliberately shipped **without** coordinates: it carries only the address an owner
    /// would actually type, and the app geocodes it on launch. That is the whole point —
    /// it proves a business becomes discoverable on the map because it registered a real
    /// address, not because someone hand-placed a pin for it.
    static let moBarberShop = Provider(
        id: UUID(uuidString: "77777777-1111-4111-8111-777777777777") ?? UUID(),
        name: "MoBarberShop",
        specialistName: "Modestas Urbonas",
        craft: "Barberis",
        category: .hair,
        district: "Centras",
        location: BusinessAddress(street: "Respublikos g. 1", city: "Panevėžys"),
        rating: 4.9,
        visitCount: 268,
        imageName: "vintage_barber_chair_interior",
        about: "Barbershop Panevėžio centre. Tikslūs perėjimai, barzdos formavimas karštu rankšluosčiu ir aiškūs priežiūros patarimai kasdienai.",
        services: [
            ServiceOffering(name: "Kirpimas", durationMinutes: 45, price: 30, detail: "Fade arba klasika"),
            ServiceOffering(name: "Barzda", durationMinutes: 30, price: 20, detail: "Formavimas ir karštas rankšluostis"),
            ServiceOffering(name: "Kirpimas ir barzda", durationMinutes: 60, price: 40, detail: "Pilnas atnaujinimas")
        ],
        nextSlot: AppDate.time(16, 30),
        reviewCount: 320,
        phone: "+370 682 41 190",
        photoNames: [
            "vintage_barber_chair_interior",
            "mid_fade_haircut_profile",
            "low_fade_haircut",
            "man_short_haircut_portrait"
        ],
        openingHours: weekdayHours(open: 9, close: 19, saturday: (10, 16))
    )

    static let providers: [Provider] = [
        noorSkinStudio, commonThread, petalStem, formaHair, studioNoma,
        lakuKambarys, tylu, dantuNamai, moBarberShop
    ]

    static var bookings: [Booking] {
        [
            Booking(
                providerID: studioNoma.id,
                providerName: studioNoma.name,
                specialistName: studioNoma.specialistName,
                address: studioNoma.address,
                imageName: studioNoma.imageName,
                serviceName: "Kirpimas ir sušukavimas",
                start: AppDate.time(10, 30, dayOffset: 1),
                durationMinutes: 60,
                price: 65,
                status: .confirmed,
                clientName: clientName,
                clientNote: "Pirmą kartą renkasi trumpesnį kirpimą",
                visitNumber: 3,
                previousVisit: AppDate.time(11, 0, dayOffset: -42)
            ),
            Booking(
                providerID: studioNoma.id,
                providerName: studioNoma.name,
                specialistName: studioNoma.specialistName,
                address: studioNoma.address,
                imageName: studioNoma.imageName,
                serviceName: "Kirpimas",
                start: AppDate.time(10, 30, dayOffset: 14),
                durationMinutes: 45,
                price: 45,
                status: .confirmed,
                clientName: clientName,
                visitNumber: 4,
                previousVisit: AppDate.time(10, 30, dayOffset: 1)
            ),
            Booking(
                providerID: studioNoma.id,
                providerName: studioNoma.name,
                specialistName: studioNoma.specialistName,
                address: studioNoma.address,
                imageName: studioNoma.imageName,
                serviceName: "Kirpimas",
                start: AppDate.time(9, 0),
                durationMinutes: 45,
                price: 45,
                status: .confirmed,
                clientName: "Lina Petrauskaitė",
                clientNote: "Mėgsta tylų vizitą",
                visitNumber: 7,
                previousVisit: AppDate.time(9, 0, dayOffset: -28)
            ),
            Booking(
                providerID: studioNoma.id,
                providerName: studioNoma.name,
                specialistName: studioNoma.specialistName,
                address: studioNoma.address,
                imageName: studioNoma.imageName,
                serviceName: "Kirpimas ir sušukavimas",
                start: AppDate.time(12, 30),
                durationMinutes: 60,
                price: 65,
                status: .confirmed,
                clientName: "Rūta Balčiūnė",
                clientNote: "Prašė palikti ilgesnį viršų",
                visitNumber: 2,
                previousVisit: AppDate.time(12, 0, dayOffset: -35)
            ),
            Booking(
                providerID: studioNoma.id,
                providerName: studioNoma.name,
                specialistName: studioNoma.specialistName,
                address: studioNoma.address,
                imageName: studioNoma.imageName,
                serviceName: "Barzdos tvarkymas",
                start: AppDate.time(14, 0),
                durationMinutes: 30,
                price: 25,
                status: .confirmed,
                clientName: "Tomas Žukauskas",
                visitNumber: 5,
                previousVisit: AppDate.time(14, 0, dayOffset: -21)
            ),
            Booking(
                providerID: studioNoma.id,
                providerName: studioNoma.name,
                specialistName: studioNoma.specialistName,
                address: studioNoma.address,
                imageName: studioNoma.imageName,
                serviceName: "Kirpimas",
                start: AppDate.time(16, 0),
                durationMinutes: 45,
                price: 45,
                // The only appointment waiting for approval: this client's own history
                // has two no-shows, so `BookingApprovalPolicy` holds it back.
                status: .pending,
                clientName: "Kipras Adomaitis",
                clientNote: "Kaip praeitą kartą — mid fade",
                visitNumber: 9,
                previousVisit: AppDate.time(16, 0, dayOffset: -16)
            ),
            Booking(
                providerID: noorSkinStudio.id,
                providerName: noorSkinStudio.name,
                specialistName: noorSkinStudio.specialistName,
                address: noorSkinStudio.address,
                imageName: noorSkinStudio.imageName,
                serviceName: "Greitas švytėjimas",
                start: AppDate.time(17, 30, dayOffset: -20),
                durationMinutes: 30,
                price: 65,
                status: .completed,
                clientName: clientName,
                visitNumber: 1
            )
        ] + teamBookings + visitHistory
    }

    /// Completed visits behind today, so the client base has a real history to
    /// measure. Demo content only — every statistic is computed from these records.
    static var visitHistory: [Booking] {
        pastVisits("Lina Petrauskaitė", "Kirpimas", 45, 45, hour: 9, offsets: [-28, -56, -84, -112, -140, -168])
            + pastVisits("Rūta Balčiūnė", "Kirpimas ir sušukavimas", 60, 65, hour: 12, offsets: [-35])
            + pastVisits("Tomas Žukauskas", "Barzdos tvarkymas", 30, 25, hour: 14, offsets: [-21, -42, -63, -84])
            + pastVisits("Kipras Adomaitis", "Kirpimas", 45, 45, hour: 16, offsets: [-16, -32, -48, -80, -96, -112, -128])
            + pastVisits(clientName, "Kirpimas ir sušukavimas", 60, 65, hour: 11, offsets: [-42, -90])
    }

    /// Demo Beauty Passport records. The UI never reads this directly — the store
    /// links each entry to its booking and serves them per client.
    static var passportEntries: [BeautyPassportEntry] {
        [
            passport(
                "B0000001",
                client: "Kipras Adomaitis",
                dayOffset: -16,
                hour: 16,
                service: "Kirpimas",
                specialist: specialistName,
                summary: "Mid fade su tekstūruotu viršumi, šonai nuleisti iki odos ties ausimi.",
                before: "man_overgrown_hair_profile",
                after: "mid_fade_haircut_profile",
                details: [
                    BeautyPassportDetail(field: .clipperGuards, value: "Nr. 1 apačia, Nr. 2 šonai, Nr. 3 perėjimas"),
                    BeautyPassportDetail(field: .technique, value: "Mid fade, minkštas perėjimas, kontūrai žirklėmis"),
                    BeautyPassportDetail(field: .length, value: "Viršus 4 cm, priekis 5 cm"),
                    BeautyPassportDetail(title: "Sriuba", value: "Kaklo linija palikta natūrali")
                ],
                products: ["Matinė pasta", "Druskos purškiklis"],
                note: "Nemėgsta blizgesio — palikti matinį finišą. Kirpti kas 4 sav."
            ),
            passport(
                "B0000002",
                client: "Kipras Adomaitis",
                dayOffset: -48,
                hour: 16,
                service: "Kirpimas",
                specialist: specialistName,
                summary: "Low fade, viršus paliktas ilgesnis, šukuosena į šoną.",
                before: "man_haircut_back_view",
                after: "low_fade_haircut",
                details: [
                    BeautyPassportDetail(field: .clipperGuards, value: "Nr. 1 apačia, Nr. 3 šonai"),
                    BeautyPassportDetail(field: .technique, value: "Low fade, retinimas žirklėmis viršuje"),
                    BeautyPassportDetail(field: .length, value: "Viršus 5 cm")
                ],
                products: ["Matinė pasta"],
                note: "Sakė, kad šonai buvo per trumpi — kitą kartą pakelti perėjimą."
            ),
            passport(
                "B0000003",
                client: "Kipras Adomaitis",
                dayOffset: -96,
                hour: 16,
                service: "Kirpimas",
                specialist: specialistName,
                summary: "Klasikinis trumpas kirpimas su tvarkingu kontūru.",
                before: "man_long_hair_before_cut",
                after: "man_short_haircut_portrait",
                details: [
                    BeautyPassportDetail(field: .technique, value: "Klasika, be fade"),
                    BeautyPassportDetail(field: .length, value: "Viršus 6 cm, šonai Nr. 4")
                ],
                products: [],
                note: nil
            ),
            passport(
                "B0000004",
                client: "Lina Petrauskaitė",
                dayOffset: -28,
                hour: 9,
                service: "Kirpimas",
                specialist: specialistName,
                summary: "Ilgis iki raktikaulio, veidą įrėminantys sluoksniai.",
                before: "woman_brown_hair_before_cut",
                after: "woman_blunt_layers_cut",
                details: [
                    BeautyPassportDetail(field: .length, value: "Nuimta 6 cm, ilgis iki raktikaulio"),
                    BeautyPassportDetail(field: .technique, value: "Tiesus pjūvis, minkšti sluoksniai prie veido"),
                    BeautyPassportDetail(field: .care, value: "Šukuosena su apvaliu šepečiu, be karščio kas antrą dieną")
                ],
                products: ["Termo apsauga", "Plaukų aliejus galiukams"],
                note: "Augina ilgį — kirpti tik galiukus."
            )
        ].compactMap { $0 }
    }

    private static func passport(
        _ seed: String,
        client: String,
        dayOffset: Int,
        hour: Int,
        service: String,
        specialist: String,
        summary: String,
        before: String?,
        after: String?,
        details: [BeautyPassportDetail],
        products: [String],
        note: String?
    ) -> BeautyPassportEntry? {
        guard let id = clientID(for: client) else { return nil }
        return BeautyPassportEntry(
            id: UUID(uuidString: "\(seed)-0000-4000-8000-000000000000") ?? UUID(),
            clientID: id,
            date: AppDate.time(hour, 0, dayOffset: dayOffset),
            serviceName: service,
            specialistName: specialist,
            category: .beauty,
            summary: summary,
            beforeImageName: before,
            afterImageName: after,
            details: details,
            products: products,
            specialistNote: note
        )
    }

    /// No-shows and late cancellations kept as their own history.
    ///
    /// Kipras is the demo case for the approval rule: two recorded no-shows, so his
    /// new bookings are held for approval. Everyone else books straight through.
    static var attendanceEvents: [ClientAttendanceEvent] {
        [
            attendance("Kipras Adomaitis", dayOffset: -64, kind: .noShow, service: "Kirpimas"),
            attendance("Kipras Adomaitis", dayOffset: -144, kind: .noShow, service: "Kirpimas"),
            attendance("Rūta Balčiūnė", dayOffset: -70, kind: .lateCancellation, service: "Kirpimas ir sušukavimas")
        ].compactMap { $0 }
    }

    private static func pastVisits(
        _ client: String,
        _ service: String,
        _ minutes: Int,
        _ price: Double,
        hour: Int,
        offsets: [Int]
    ) -> [Booking] {
        let ordered = offsets.sorted()
        return ordered.enumerated().map { index, offset in
            Booking(
                providerID: studioNoma.id,
                providerName: studioNoma.name,
                specialistName: studioNoma.specialistName,
                address: studioNoma.address,
                imageName: studioNoma.imageName,
                serviceName: service,
                start: AppDate.time(hour, 0, dayOffset: offset),
                durationMinutes: minutes,
                price: price,
                status: .completed,
                clientName: client,
                visitNumber: index + 1,
                previousVisit: index > 0 ? AppDate.time(hour, 0, dayOffset: ordered[index - 1]) : nil
            )
        }
    }

    private static func attendance(
        _ client: String,
        dayOffset: Int,
        kind: ClientAttendanceKind,
        service: String
    ) -> ClientAttendanceEvent? {
        guard let id = clientID(for: client) else { return nil }
        return ClientAttendanceEvent(
            clientID: id,
            date: AppDate.time(10, 0, dayOffset: dayOffset),
            kind: kind,
            serviceName: service
        )
    }

    /// Demo appointments for the two colleagues, used only by the team calendar.
    static var teamBookings: [Booking] {
        [
            teamBooking("Adas Jasiūnas", "Vyriškas kirpimas", AppDate.time(9, 30), 40, 32, .confirmed, "Justina Rimšaitė"),
            teamBooking("Adas Jasiūnas", "Kirpimas ir barzda", AppDate.time(11, 15), 60, 45, .confirmed, "Grėtė Milaitė"),
            teamBooking("Adas Jasiūnas", "Vyriškas kirpimas", AppDate.time(14, 0), 40, 32, .confirmed, "Domas Jankus"),
            teamBooking("Rokas Abromavičius", "Vyriškas kirpimas", AppDate.time(10, 0), 40, 32, .confirmed, "Mantas Sereika"),
            teamBooking("Rokas Abromavičius", "Barzdos tvarkymas", AppDate.time(13, 30), 30, 25, .confirmed, "Arūnas Petkus"),
            teamBooking("Emilis Zupka", "Dažymas ir tonavimas", AppDate.time(9, 30), 120, 140, .confirmed, "Lina Petrauskaitė"),
            teamBooking("Emilis Zupka", "Šaknų korekcija", AppDate.time(13, 0), 90, 95, .confirmed, "Rūta Balčiūnė")
        ]
    }

    private static func teamBooking(
        _ specialist: String,
        _ service: String,
        _ start: Date,
        _ minutes: Int,
        _ price: Double,
        _ status: BookingStatus,
        _ client: String
    ) -> Booking {
        Booking(
            providerID: salonFloorID,
            providerName: homeVenue,
            specialistName: specialist,
            address: studioNoma.address,
            imageName: studioNoma.imageName,
            serviceName: service,
            start: start,
            durationMinutes: minutes,
            price: price,
            status: status,
            clientName: client
        )
    }

    static var blocks: [TimeBlock] {
        [
            TimeBlock(
                specialistName: specialistName,
                title: "Maistas",
                start: AppDate.time(11, 0),
                durationMinutes: 30
            )
        ]
    }

    static let favoriteProviderIDs: Set<UUID> = [studioNoma.id, noorSkinStudio.id]

    /// Seeded reviews for the development catalogue.
    ///
    /// Every one of them is tagged `.demoCatalogue`, so the profile can show what a
    /// reviewed business looks like without a single line of invented production data.
    /// Reviews clients write in the app carry `.client` and live alongside these.
    static var reviews: [ProviderReview] {
        [
            review(moBarberShop.id, "Karolis Mockus", 5, "Tiksliausias fade mieste. Modestas visada paklausia, kaip augo plaukai nuo praėjusio karto.", -4),
            review(moBarberShop.id, "Arūnas Petkus", 5, "Barzda su karštu rankšluosčiu — verta kiekvieno euro.", -12),
            review(moBarberShop.id, "Domas Jankus", 4, "Puikus kirpimas, tik teko šiek tiek palaukti.", -21),
            review(studioNoma.id, "Lina Petrauskaitė", 5, "Kipras vienintelis, kuris nekerpa daugiau, nei prašai. Ilgį auginu jau metus.", -8),
            review(studioNoma.id, "Rūta Balčiūnė", 5, "Rami studija, jokios skubos. Išeinu su šukuosena, kurią pakartoju ir namuose.", -30),
            review(formaHair.id, "Mantas Sereika", 4, "Geras klasikinis kirpimas, patogus laikas po darbo.", -15),
            review(tylu.id, "Justina Rimšaitė", 5, "Po gydomojo masažo nugara pirmą kartą per mėnesį neskaudėjo.", -6),
            review(noorSkinStudio.id, "Grėtė Milaitė", 5, "Konsultacija ilgesnė nei pati procedūra — ir tai geriausia dalis.", -18),
            review(lakuKambarys.id, "Ieva Kazlauskaitė", 5, "Danga išlaikė tris savaites be nė vieno įskilimo.", -25),
            review(dantuNamai.id, "Tomas Žukauskas", 4, "Higiena be skausmo, viskas paaiškinta suprantamai.", -40)
        ]
    }

    private static func review(
        _ providerID: UUID,
        _ author: String,
        _ rating: Int,
        _ text: String,
        _ dayOffset: Int
    ) -> ProviderReview {
        ProviderReview(
            providerID: providerID,
            authorName: author,
            rating: rating,
            text: text,
            date: AppDate.time(12, 0, dayOffset: dayOffset),
            source: .demoCatalogue
        )
    }
}
