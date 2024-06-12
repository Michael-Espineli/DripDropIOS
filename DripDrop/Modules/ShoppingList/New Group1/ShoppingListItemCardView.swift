//
//  ShoppingListItemCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/19/24.
//

import SwiftUI

struct ShoppingListItemCardView: View {
    let shoppingListItem: ShoppingListItem
    var body: some View {
            HStack{
                colorIcon
                if UIDevice.isIPhone {
                    VStack{
                        details
                        cat
                    }
                } else {
                    HStack{
                        details
                        cat
                    }
                }
            }
            .padding(10)
    }
}
extension ShoppingListItemCardView{
    // Data Base , Chemical , Part , Custom
    func getColor(subCategory:ShoppingListSubCategory) -> Color{
        switch subCategory{
        case .dataBase:
            return Color.blue
        case .chemical:
            return Color.green
        case .part:
            return Color.yellow
        case .custom:
            return Color.purple
        default:
            return Color.gray
        }
    }
    var details: some View {
        HStack{
            Text("\(shoppingListItem.name)")
            switch shoppingListItem.status {
            case .installed:
                Text("\(shoppingListItem.status.rawValue)")
                    .font(.footnote)
                    .padding(5)
                    .background(Color.green)
                    .foregroundColor(Color.black)
                    .cornerRadius(5)
                
                    .padding(5)
            case .purchased:
                Text("\(shoppingListItem.status.rawValue)")
                    .font(.footnote)
                    .padding(5)
                    .background(Color.yellow)
                    .foregroundColor(Color.black)
                    .cornerRadius(5)
                
                    .padding(5)
            case .needToPurchase:
                Text("\(shoppingListItem.status.rawValue)")
                    .font(.footnote)
                    .padding(5)
                    .background(Color.red)
                    .foregroundColor(Color.white)
                    .cornerRadius(5)
                
                    .padding(5)
            default:
                Text("\(shoppingListItem.status.rawValue)")
                    .font(.footnote)
                    .padding(5)
                    .background(Color.gray)
                    .foregroundColor(Color.white)
                    .cornerRadius(5)
                
                    .padding(5)
            }

        }
    }
    var cat: some View {
        ZStack{
            switch shoppingListItem.category {
            case .customer:
                Text("\(shoppingListItem.category.rawValue)")
                if let customerName = shoppingListItem.customerName {
                    Text("\(customerName)")
                }
            case .personal:
                Text("\(shoppingListItem.category.rawValue)")
            case .job:
                if let job = shoppingListItem.jobId {
                    Text("\(job)")
                }
            default:
                Text("\(shoppingListItem.category.rawValue)")
            }
        }
    }
    var colorIcon: some View {
        VStack{
            switch shoppingListItem.category{
            case .personal:
                Image(systemName: "figure.stand.line.dotted.figure.stand")
                    .foregroundColor(getColor(subCategory: shoppingListItem.subCategory))
            case .job:
                Image(systemName: "spigot.fill")
                    .foregroundColor(getColor(subCategory: shoppingListItem.subCategory))
            case .customer:
                Image(systemName: "testtube.2")
                    .foregroundColor(getColor(subCategory: shoppingListItem.subCategory))
            default:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(getColor(subCategory: shoppingListItem.subCategory))
            }
        }
    }
}
