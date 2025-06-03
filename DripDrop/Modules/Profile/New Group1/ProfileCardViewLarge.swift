//
//  ProfileCardViewLarge.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/1/23.
//

import SwiftUI

struct ProfileCardViewLarge: View {
    @Binding var showSignInView:Bool
    @State var user:DBUser
    var body: some View {
        VStack{
            HStack{
image
                VStack{
                    Text("\(user.firstName ?? "...Loading") \(user.lastName ?? "...Loading")")
                        .font(.title)
                    Text("Company")
                    Text("Postion")

                }
            }
        }
        .padding()
        .background(Color.gray)
        .foregroundColor(Color.white)
        .cornerRadius(10)
    }
}
extension ProfileCardViewLarge{
    var image: some View {
        ZStack{
            Circle()
                .fill(Color.red)
                .frame(maxWidth:80 ,maxHeight:80)
            if let urlString = user.photoUrl,let url = URL(string: urlString){
                AsyncImage(url: url){ image in
                    image
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(Color.white)
                        .frame(maxWidth:75 ,maxHeight:75)
                        .cornerRadius(75)
                } placeholder: {
                    Image(systemName:"person.circle")
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(Color.basicFontText)
                        .frame(maxWidth:75 ,maxHeight:75)
                        .cornerRadius(75)
                }
            }
        }
        .frame(maxWidth: 75,maxHeight:75)
        .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
    }

}
struct ProfileCardViewLarge_Previews: PreviewProvider {
    static var previews: some View {
        @State var showSignInView: Bool = false

        ProfileCardViewLarge(showSignInView: $showSignInView, user: DBUser(id: "", email: "",firstName: "Michael",lastName: "Espineli", exp: 0,recentlySelectedCompany: ""))
    }
}
