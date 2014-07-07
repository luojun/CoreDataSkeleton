//
//  MasterViewController.m
//  CoreDataSkeleton
//
//  Created by Jun Luo on 2014-07-04.
//  Copyright (c) 2014 Jun Luo. All rights reserved.
//

#import "UserViewController.h"
#import "RepoViewController.h"
#import "CoreDataHelper.h"
#import "CoreDataFetcher.h"

@interface UserViewController () <CoreDataFetcherDelegate>

@property (nonatomic, strong) CoreDataFetcher* fetcher;

@end

@implementation UserViewController

#pragma mark - life cycle

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewUser:)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.repoViewController = (RepoViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    [self setupFetcher];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.fetcher.paused = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.fetcher.paused = YES;
}

#pragma mark - set up

- (void)setupFetcher
{
    self.fetcher = [[CoreDataFetcher alloc] initWithTableView:self.tableView];
    self.fetcher.fetchedResultsController = self.fetchedResultsController;
    self.fetcher.delegate = self;
    self.fetcher.reuseIdentifier = @"Cell";
}

#pragma mark - GitHub user

- (void)addNewUser:(id)sender {
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Add a GitHub User" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField * alertTextField = [alert textFieldAtIndex:0];
    alertTextField.placeholder = @"GitHub user name";
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (0 == buttonIndex)
        return;
    
    NSString * text= [alertView textFieldAtIndex:0].text;
    NSString *userName = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSLog(@"Entered: %@", userName);
    [self createNewUser:userName];
}

- (void)createNewUser:(NSString *)userName
{
    NSManagedObjectContext *mainContext = [CoreDataHelper defaultMainContext];
    if (![CoreDataHelper itemExistsWithValue:userName forAttribute:@"userName" inEntity:@"User" forContext:mainContext]) {
        static NSString * gitHubUsers = @"https://api.github.com/users/%@";
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithURL:[NSURL URLWithString:[NSString stringWithFormat:gitHubUsers, userName]]
                completionHandler:^(NSData *data,
                                    NSURLResponse *response,
                                    NSError *error) {
                    
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    if (httpResponse.statusCode == 200) {
                        NSError *jsonError;
                        NSDictionary *userDic = [NSJSONSerialization JSONObjectWithData:data
                                                                                options:NSJSONReadingAllowFragments
                                                                                  error:&jsonError];
                        if (!jsonError) {
                            NSString *avatarURL = [userDic objectForKey:@"avatar_url"];
                            NSString *userEtag = [httpResponse.allHeaderFields objectForKey:@"ETag"];
                            
                            NSManagedObjectContext *tempContext = [CoreDataHelper tempContext];
                            [tempContext performBlock:^{
                                NSManagedObject *userObject = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:tempContext];
                                [userObject setValue:userName forKey:@"userName"];
                                [userObject setValue:avatarURL forKey:@"avatarURL"];
                                [userObject setValue:userEtag forKey:@"userEtag"];
                                
                                [CoreDataHelper saveTempContext:tempContext];
                            }];
                        }
                    } else {
                        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Server responded with %d", httpResponse.statusCode]
                                                                         message:[[NSJSONSerialization JSONObjectWithData:data
                                                                                                                 options:NSJSONReadingAllowFragments
                                                                                                                   error:nil] description]
                                                                        delegate:self
                                                               cancelButtonTitle:@"Continue"
                                                               otherButtonTitles:nil];
                        [alert show];
                    }
                }] resume];
    } else {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"User exists" message:[NSString stringWithFormat:@"GitHub user %@ was already added!", userName] delegate:self cancelButtonTitle:@"Continue" otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        [(RepoViewController *)[[segue destinationViewController] topViewController] setDetailObject:self.fetcher.selectedObject];
    }
}

#pragma mark - fetcher delegate

- (void)configureCell:(UITableViewCell *)cell withObject:(id)object
{
    UILabel *userNameView = (UILabel *) [cell.contentView viewWithTag:1];
    UIImageView *avatarView = (UIImageView *) [cell.contentView viewWithTag:2];
    userNameView.text = [[object valueForKey:@"userName"] description];
    NSURL *imageURL = [NSURL URLWithString:[object valueForKey:@"avatarURL"]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
        dispatch_async(dispatch_get_main_queue(), ^{
            avatarView.image = [UIImage imageWithData:imageData];
        });
    });
}

- (void)deleteObject:(NSManagedObject *)object
{
    NSString* actionName = [NSString stringWithFormat:NSLocalizedString(@"Delete \"%@\"", @"Delete undo action name"), [object valueForKey:@"userName"]];
    [self.undoManager setActionName:actionName];
    [object.managedObjectContext deleteObject:object];
}

#pragma mark - fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSManagedObjectContext *mainContext = [CoreDataHelper defaultMainContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:mainContext];
    request.entity = entity;
    request.fetchBatchSize = 20;
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"userName" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    request.sortDescriptors = sortDescriptors;
    
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:mainContext sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController = controller;

    return _fetchedResultsController;
}

#pragma mark - undo

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSUndoManager*)undoManager
{
    return [CoreDataHelper defaultMainContext].undoManager;
}

@end
