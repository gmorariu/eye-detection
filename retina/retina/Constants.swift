//
//  Constants.swift
//  retina
//
//  Created by George Morariu on 8/23/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import Foundation
import AWSCognitoIdentityProvider

class Constants {
    static let clientId = "xxx"
    static let clientSecret = "xxx"
    static let poolId = "xxx"
    static let region = AWSRegionType.USWest2
    static let identityPoolId = "xxx"
    
    static let apiEndpoint = "https://xxx.execute-api.us-west-2.amazonaws.com/prod/"
    
    static let agree_label = "I Agree"
    static let disclaimer = """
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
    EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
    FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
    LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
    NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
    THE POSSIBILITY OF SUCH DAMAGE.
    """
    static let disclaimer_title = "Terms of use"
    static let access_account_error =  "Cannot access your account at this time. Please try later."
    static let add_player_error =  "Cannot add player at this time. Please try later."
}
