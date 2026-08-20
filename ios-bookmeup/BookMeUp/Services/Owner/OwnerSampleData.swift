import Foundation

/// Demo content for the owner environment.
///
/// Everything a screen would otherwise be tempted to hardcode lives here: the
/// business, its location, the team, the roles, the service catalogue and the
/// resources. The demo is tuned for MoBarberShop, but the models it fills are the
/// universal ones — nothing about a chair or a haircut is baked into the platform.
nonisolated enum OwnerSampleData {
    // MARK: - Business

    static let businessID = id("B1000000")

    static var business: Business {
        Business(
            id: businessID,
            name: "MoBarberShop",
            legalName: "MB MoBarberShop",
            about: "Barbershop Panevėžyje: kirpimai, barzdos ir tvarkinga kasdienė forma.",
            phone: "+37060000000",
            email: "info@mobarbershop.lt",
            website: "mobarbershop.lt",
            countryCode: "LT",
            currencyCode: "EUR",
            defaultLanguage: "lt",
            timeZoneIdentifier: "Europe/Vilnius",
            vatRegistered: false,
            vatNumber: nil,
            vatRatePercent: 21
        )
    }

    // MARK: - Locations

    static let panevezysID = id("L1000000")

    static var locations: [BusinessLocation] {
        [
            BusinessLocation(
                id: panevezysID,
                businessID: businessID,
                name: "MoBarberShop Panevėžys",
                address: "Respublikos g. 40",
                city: "Panevėžys",
                phone: "+37060000000",
                hours: .standard(opens: 9 * 60, closes: 19 * 60, closedWeekdays: [7])
            )
        ]
    }

    // MARK: - Roles

    static let ownerRoleID = id("R1000000")
    static let managerRoleID = id("R2000000")
    static let administratorRoleID = id("R3000000")
    static let employeeRoleID = id("R4000000")

    static var roles: [StaffRole] {
        [
            StaffRole(id: ownerRoleID, kind: .owner, name: "Savininkas", permissions: RolePresets.owner),
            StaffRole(id: managerRoleID, kind: .manager, name: "Vadovas", permissions: RolePresets.manager),
            StaffRole(
                id: administratorRoleID,
                kind: .administrator,
                name: "Administratorius",
                permissions: RolePresets.administrator
            ),
            StaffRole(id: employeeRoleID, kind: .employee, name: "Darbuotojas", permissions: RolePresets.employee)
        ]
    }

    // MARK: - Services

    static var serviceCatalogue: [ServiceOffering] {
        [
            ServiceOffering(id: id("51000000"), name: "Kirpimas", durationMinutes: 40, price: 25, detail: "Fade arba klasika"),
            ServiceOffering(id: id("52000000"), name: "Kirpimas ir barzda", durationMinutes: 60, price: 38, detail: "Pilnas atnaujinimas"),
            ServiceOffering(id: id("53000000"), name: "Barzdos tvarkymas", durationMinutes: 30, price: 18, detail: "Kontūrai ir priežiūra"),
            ServiceOffering(id: id("54000000"), name: "Vaikų kirpimas", durationMinutes: 30, price: 18, detail: "Iki 12 metų"),
            ServiceOffering(id: id("55000000"), name: "Skutimas peiliuku", durationMinutes: 40, price: 28, detail: "Karšti rankšluosčiai")
        ]
    }

    // MARK: - Resources

    static var resources: [BusinessResource] {
        [
            BusinessResource(id: id("C1000000"), locationID: panevezysID, name: "Vieta 1", type: .chair),
            BusinessResource(id: id("C2000000"), locationID: panevezysID, name: "Vieta 2", type: .chair),
            BusinessResource(id: id("C3000000"), locationID: panevezysID, name: "Vieta 3", type: .chair)
        ]
    }

    // MARK: - Staff

    static let kiprasID = id("S1000000")
    static let adasID = id("S2000000")
    static let gytisID = id("S3000000")
    static let rokasID = id("S4000000")
    static let emilisID = id("S5000000")

    /// The signed-in membership of the demo. In production this comes from the account
    /// and its business membership — never from a name check.
    static let currentStaffID = kiprasID

    static var staff: [StaffMembership] {
        [
            membership(kiprasID, "Kipras Norkus", role: ownerRoleID, level: .master, phone: "+37060000001"),
            membership(adasID, "Adas Šimkus", role: employeeRoleID, level: .senior, phone: "+37060000002"),
            membership(gytisID, "Gytis Petraitis", role: employeeRoleID, level: .specialist, phone: "+37060000003"),
            membership(rokasID, "Rokas Vasiliauskas", role: employeeRoleID, level: .junior, phone: "+37060000004"),
            membership(emilisID, "Emilis Jankauskas", role: employeeRoleID, level: .specialist, phone: "+37060000005")
        ]
    }

    private static func membership(
        _ id: UUID,
        _ name: String,
        role: UUID,
        level: CareerLevel,
        phone: String
    ) -> StaffMembership {
        StaffMembership(
            id: id,
            businessID: businessID,
            memberName: name,
            craft: "Barberis",
            roleID: role,
            status: .active,
            locationIDs: [panevezysID],
            serviceIDs: serviceCatalogue.map(\.id),
            phone: phone,
            email: "",
            careerLevel: level,
            compensation: StaffCompensation(kind: .servicePercentage, servicePercent: 45, retailPercent: 10),
            joinedAt: AppDate.time(9, 0, dayOffset: -420)
        )
    }

    // MARK: - Shifts and leave

    /// Monday–Saturday for everyone, so the demo has a real occupancy denominator.
    static var shifts: [WorkShift] {
        staff.flatMap { member in
            (1...6).map { weekday in
                WorkShift(
                    staffID: member.id,
                    locationID: panevezysID,
                    weekday: weekday,
                    startMinutes: 9 * 60,
                    endMinutes: 19 * 60
                )
            }
        }
    }

    /// One request waiting for a decision, so the approval path has something real.
    static var leaveRequests: [LeaveRequest] {
        [
            LeaveRequest(
                id: id("A1000000"),
                staffID: rokasID,
                kind: .vacation,
                start: AppDate.time(9, 0, dayOffset: 12),
                end: AppDate.time(19, 0, dayOffset: 18),
                note: "Suplanuota kelionė",
                status: .pending,
                requestedAt: AppDate.time(11, 0, dayOffset: -2)
            ),
            LeaveRequest(
                id: id("A2000000"),
                staffID: gytisID,
                kind: .training,
                start: AppDate.time(9, 0, dayOffset: 26),
                end: AppDate.time(19, 0, dayOffset: 26),
                note: "Barberių mokymai",
                status: .approved,
                requestedAt: AppDate.time(11, 0, dayOffset: -9)
            )
        ]
    }

    // MARK: - Messages

    /// The starting set of client messages. Bodies use the shared variables, so the
    /// preview and the future sender read the same text.
    static var messageTemplates: [MessageTemplate] {
        [
            MessageTemplate(
                id: id("M1000000"),
                trigger: .bookingConfirmed,
                title: "Rezervacijos patvirtinimas",
                channels: [.sms, .push],
                offsetMinutes: 0,
                body: "\(MessageVariable.clientFirstName.token), laikas rezervuotas: \(MessageVariable.appointmentDate.token) \(MessageVariable.appointmentTime.token) · \(MessageVariable.businessName.token)."
            ),
            MessageTemplate(
                id: id("M2000000"),
                trigger: .bookingReminder,
                title: "Priminimas dieną prieš",
                channels: [.sms],
                offsetMinutes: -24 * 60,
                body: "Rytoj \(MessageVariable.appointmentTime.token) laukiame pas \(MessageVariable.employeeName.token). \(MessageVariable.locationName.token)."
            ),
            MessageTemplate(
                id: id("M3000000"),
                trigger: .rebooking,
                title: "Laikas registruotis",
                channels: [.push],
                isEnabled: false,
                offsetMinutes: 0,
                body: "\(MessageVariable.clientFirstName.token), įprastai lankaisi maždaug dabar. Rezervuoti: \(MessageVariable.bookingLink.token)"
            ),
            MessageTemplate(
                id: id("M4000000"),
                trigger: .winBack,
                title: "Mes tavęs pasiilgome",
                channels: [.sms],
                isEnabled: false,
                offsetMinutes: 0,
                body: "\(MessageVariable.clientFirstName.token), seniai matėmės. \(MessageVariable.businessName.token) laukia — \(MessageVariable.bookingLink.token)"
            )
        ]
    }

    // MARK: - Audit

    /// A few real-looking history lines so the journal's shape is visible. The live
    /// journal will be written by the actions themselves, not seeded.
    static var auditEvents: [AuditEvent] {
        [
            AuditEvent(
                id: id("E1000000"),
                date: AppDate.time(9, 12, dayOffset: -1),
                actorName: "Kipras Norkus",
                actorType: .owner,
                action: .pricingChanged,
                entityTitle: "Kirpimas ir barzda",
                locationID: panevezysID,
                summary: "Kaina atnaujinta paslaugų kataloge."
            ),
            AuditEvent(
                id: id("E2000000"),
                date: AppDate.time(17, 40, dayOffset: -2),
                actorName: "Adas Šimkus",
                actorType: .employee,
                action: .bookingMoved,
                entityTitle: "Rezervacija",
                locationID: panevezysID,
                summary: "Vizitas perkeltas į kitą dienos laiką."
            ),
            AuditEvent(
                id: id("E3000000"),
                date: AppDate.time(10, 5, dayOffset: -5),
                actorName: "Sistema",
                actorType: .system,
                action: .scheduleChanged,
                entityTitle: "Darbo grafikas",
                locationID: panevezysID,
                summary: "Pritaikytas savaitės grafiko šablonas."
            )
        ]
    }

    private static func id(_ seed: String) -> UUID {
        UUID(uuidString: "\(seed)-0000-4000-8000-000000000000") ?? UUID()
    }
}
