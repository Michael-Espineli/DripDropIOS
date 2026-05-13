////
////  TestData+Extension.swift
////  DripDrop
////
////  Created by Michael Espineli on 11/11/25.
////
//
//import Foundation
//
//extension TestDataViewModel {
//    func setUpTestCompany() {
//        
//        //Set Up Test Customers
//        setUpTestCustomers()
//
//        //Set Up Service Locations
//        setUpTestServiceLocations()
//        //Set Up Bodies of Water
//        setUpTestBodiesOfWater()
//        //Set Up Equipment
//        setUpTestEquipment()
//        //Set Up test Company Users
//        
//        setUpTestCompanyUsers()
//        
//        //Set Up Roles
//        setUpTestRoles()
//        
//        //Set Up Fleet
//        setUpTestFleet()
//        
//        //Set Up Test Jobs
//        setUpTestJobs()
//        
//        //Set Up Recurring Routes
//        setUpTestRecurringRoutes()
//        
//        // Set Up Service Stops
//        setUpTestServiceStops()
//        
//        //Set Up Recurring Service Stops
//        setUpTestRecurringServiceStops()
//        
//        //Set Up Active Routes
//        setUpTestActiveRoutes()
//        //Finished Uploading Test Data
//    }
//    
//    func setUpTestCustomers() {
//        print("[setUpTestCustomers] ------------------------------------")
//        Task{
//            do {
//                for customer in mockCustomerList {
//                    
//                    let fullName = customer.firstName + " " + customer.lastName
//                    print("Customer: \(fullName)")
//                    let contact:Contact = Contact(id: customer.id, name: fullName, phoneNumber: customer.phoneNumber ?? "", email: customer.email)
//                    let id = customer.id
//                    try await ds.uploadCustomer(companyId: companyId, customer: customer)
//                    try await ds.uploadCustomerContact(companyId: companyId, customerId: customer.id, contact: contact)
//                    print(" - Contact")
//                    
//                    let serviceLocation = ServiceLocation(
//                        id: customer.id,
//                        nickName: "\(customer.firstName)'s House",
//                        address: customer.billingAddress,
//                        gateCode: "",
//                        mainContact: contact,
//                        bodiesOfWaterId: [id],
//                        rateType: "",
//                        laborType: "",
//                        chemicalCost: "",
//                        laborCost: "",
//                        rate: "",
//                        customerId: customer.id,
//                        customerName: customer.firstName + " " + customer.lastName,
//                        isActive: true
//                    )
//                    
//                    print(" - Location")
//                }
//            } catch {
//                print(error)
//            }
//        }
//    }
//    func setUpTestCustomersAndOperation() {
//        print("[setUpTestCustomers] ------------------------------------")
//        Task{
//            do {
//                for customer in mockCustomerList {
//                    
//                    let fullName = customer.firstName + " " + customer.lastName
//                    print("Customer: \(fullName)")
//                    let contact:Contact = Contact(id: customer.id, name: fullName, phoneNumber: customer.phoneNumber ?? "", email: customer.email)
//                    let id = customer.id
//                    try await ds.uploadCustomer(companyId: companyId, customer: customer)
//                    try await ds.uploadCustomerContact(companyId: companyId, customerId: customer.id, contact: contact)
//                    print(" - Contact")
//                    let serviceLocation = ServiceLocation(
//                        id: customer.id,
//                        nickName: "\(customer.firstName)'s House",
//                        address: customer.billingAddress,
//                        gateCode: "",
//                        mainContact: contact,
//                        bodiesOfWaterId: [id],
//                        rateType: "",
//                        laborType: "",
//                        chemicalCost: "",
//                        laborCost: "",
//                        rate: "",
//                        customerId: customer.id,
//                        customerName: customer.firstName + " " + customer.lastName,
//                        isActive: true
//                    )
//                    try await ds.uploadCustomerServiceLocations(companyId: companyId, customer: customer, serviceLocation: serviceLocation)
//                    
//                    print(" - Location")
//                    let bodyOfWater = BodyOfWater(
//                        id: id,
//                        name: "Main",
//                        gallons: "20000",
//                        material: "Plaster",
//                        customerId: id,
//                        serviceLocationId: id,
//                        notes: "",
//                        shape: "",
//                        length: [],
//                        depth: [],
//                        width: [],
//                        lastFilled: Date(),
//                        isActive: true
//                    )
//                    try await ds.uploadServiceLocationBodyOfWater(companyId: companyId, bodyOfWater:bodyOfWater)
//                    
//                    print("Uploading Equipment For >> \(serviceLocation.customerName)")
//                    
//                    let filterId = UUID().uuidString
//                    let pumpId = UUID().uuidString
//                    
//                    print(" - Body Of Water")
//                    try await ds.addNewEquipmentWithParts(
//                        companyId: companyId,
//                        equipment: Equipment(
//                            id: filterId,
//                            name:"Filter 1",
//                            type: .filter,
//                            typeId: "",
//                            make: "",
//                            makeId: "",
//                            model: "",
//                            modelId: "",
//                            dateInstalled: Date(),
//                            status: .operational,
//                            needsService: true,
//                            lastServiceDate: Date(),
//                            serviceFrequency: 6,
//                            serviceFrequencyEvery: .monthly,
//                            nextServiceDate: getNextServiceDate(
//                                lastServiceDate: Date(),
//                                frequency: 6,
//                                every: .monthly
//                            ),
//                            
//                            notes: "",
//                            customerName: fullName,
//                            customerId: id,
//                            serviceLocationId: id,
//                            bodyOfWaterId: id,
//                            isActive: true
//                        )
//                    )
//                    // Add Basic Parts for Filter
//                    try await ds.addNewEquipmentWithParts(
//                        companyId: companyId,
//                        equipment: Equipment(
//                            id: pumpId,
//                            name:"Pump 1",
//                            type: .pump,
//                            typeId: "",
//                            make: "",
//                            makeId: "",
//                            model: "",
//                            modelId: "",
//                            dateInstalled: Date(),
//                            status: .operational,
//                            needsService: false,
//                            notes: "",
//                            customerName: fullName,
//                            customerId: id,
//                            serviceLocationId: id,
//                            bodyOfWaterId: id,
//                            isActive: true
//                        )
//                    )
//                    
//                    print(" - Equipment")
//                }
//            } catch {
//                print(error)
//            }
//        }
//    }
//    
//    func setUpTestServiceLocations() {
//        print("[setUpTestServiceLocations] ------------------------------------")
//        Task{
//            do {
//                for serviceLocation in mockLocationList {
//                    try await ds.uploadCustomerServiceLocations(companyId: companyId, customer: mockCustomerList[0], serviceLocation: serviceLocation)
//
//                }
//            } catch {
//                print(error)
//            }
//        }
//    }
//    func setUpTestBodiesOfWater() {
//        print("[setUpTestBodiesOfWater] ------------------------------------")
//        Task{
//            do {
//                for bodyOfWater in mockBOWList {
//                    try await ds.uploadServiceLocationBodyOfWater(companyId: companyId, bodyOfWater:bodyOfWater)
//
//                }
//            } catch {
//                print(error)
//            }
//        }
//    }
//    func setUpTestEquipment() {
//        print("[setUpTestEquipment] ------------------------------------")
//
//        Task{
//            do {
//                for equipment in mockEquipmentList{
//                    try await ds.addNewEquipmentWithParts(companyId: companyId,equipment: equipment)
//                }
//            } catch {
//                print(error)
//            }
//        }
//    }
//    
//    func setUpTestCompanyUsers() {
//        print("[setUpTestCompanyUsers] ------------------------------------")
//        Task{
//            do {
//                for user in mockUsers {
//                    print(user)
//                    try await ds.addCompanyUser(companyId: companyId, companyUser: user)
//                }
//            } catch {
//                print(error)
//            }
//        }
//    }
//    func setUpTestRoles() {
//        print("[setUpTestRoles] ------------------------------------")
////        Task{
////            do {
////                
////            } catch {
////                print(error)
////            }
////        }
//    }
//    func setUpTestFleet() {
//        print("[setUpTestFleet] ------------------------------------")
//        Task{
//            do {
//                for vehicle in mockVehicalList {
//                    try await ds.addNewVehical(companyId: companyId, vehical: vehicle)
//                }
//            } catch {
//                print(error)
//            }
//        }
//    }
//    func setUpTestJobs() {
//        print("[setUpTestJobs] ------------------------------------")
//        Task{
//            do {
//                for job in mockJobs {
//                    try await ds.uploadWorkOrder(companyId: companyId, workOrder: job)
//                }
//                
//            } catch {
//                print(error)
//            }
//        }
//    }
//    func setUpTestRecurringRoutes() {
//        print("[setUpTestRoutes] ------------------------------------")
//        Task{
//            do {
//                for recurringRoute in mockRecurringRouteList {
//                    try await ds.uploadRoute(companyId: companyId, recurringRoute: recurringRoute)
//                }
//                
//            } catch {
//                print(error)
//            }
//        }
//    }
//    func setUpTestServiceStops() {
//        print("[setUpTestServiceStops] ------------------------------------")
//        Task{
//            do {
//                for serviceStop in mockServiceStopList {
//                    try await ds.uploadServiceStop(companyId: companyId, serviceStop: serviceStop)
//                }
//                
//            } catch {
//                print(error)
//            }
//        }
//    }
//    func setUpTestRecurringServiceStops() {
//        print("[setUpTestRecurringServiceStops] ------------------------------------")
//        Task{
//            do {
//                for recurringServiceStop in mockRecurringServiceStopList {
//                    try await ds.addNewRecurringServiceStop(companyId: companyId, recurringServiceStop: recurringServiceStop)
//                }
//                
//            } catch {
//                print(error)
//            }
//        }
//    }
//    func setUpTestActiveRoutes() {
//        print("[setUpTestRoutes] ------------------------------------")
//        Task{
//            do {
//                for activeRoute in mockActiveRouteList {
//                    try await ds.uploadRoute(companyId: companyId, activeRoute: activeRoute)
//                }
//                
//            } catch {
//                print(error)
//            }
//        }
//    }
//}
